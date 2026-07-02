// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-arguments open source project
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp and the swift-arguments project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Argument_Primitives
public import IEEE_1003
internal import Ordinal_Primitive
internal import Tagged_Primitives
internal import Text_Primitives

extension Argument.Tokenizer {
    /// The default L3 argv tokenizer.
    ///
    /// `Argument.Tokenizer.Default` consumes a `[String]` argv and emits
    /// a stream of L1 ``Argument/Token`` values, normalizing the L2
    /// POSIX-shaped tokens from
    /// ``IEEE_1003/UtilitySyntax/Tokenizer`` and applying inline GNU
    /// long-option pre-processing.
    ///
    /// ## Tokenization stages
    ///
    /// 1. **GNU long-option pre-pass** (inline at L3 per §3.4 v1.0.7):
    ///    each argv element matching `--xxx` is emitted as a long-form
    ///    L1 token. The `--xxx=value` form is split into a
    ///    long token followed by a value token; the `--xxx value`
    ///    form leaves the following operand-shaped argv element for the
    ///    next iteration, which classifies as `.value(_)`.
    /// 2. **POSIX 12.2 fallback**: argv elements not matching long-option
    ///    shape are passed through ``IEEE_1003/UtilitySyntax/Tokenizer``
    ///    one at a time and their emitted ``IEEE_1003/UtilitySyntax/Token``
    ///    values are mapped to L1 ``Argument/Token`` per the
    ///    L2-to-L1 hand-off table.
    /// 3. **End-of-options carry-through**: after `--`, every argv element
    ///    is classified as `.positional(_)`.
    ///
    /// ## L2-to-L1 token mapping
    ///
    /// | L2 `IEEE_1003.UtilitySyntax.Token.Kind` | L1 `Argument.Token.Kind` |
    /// |---|---|
    /// | `.shortFlag(c)`              | `.shortCluster(String(c))` |
    /// | `.shortValue(s)`             | `.value(s)` |
    /// | `.shortCluster(s)`           | `.shortCluster(s)` |
    /// | `.operand(s)`                | `.positional(s)` |
    /// | `.endOfOptions`              | `.endOfOptions` |
    ///
    /// ## Why short-flag maps to single-char cluster
    ///
    /// L1's ``Argument/Token/Kind`` represents short-form options as
    /// `.shortCluster(String)` even for a single-character flag. This
    /// uniform shape lets the schema-driven parser treat `-f`,
    /// `-fv` (cluster), and `-fvalue` (concatenated value) through one
    /// case-bucket and disambiguate via the schema rather than via the
    /// token shape. The L2 tokenizer's POSIX-specific `.shortFlag(c)` vs
    /// `.shortValue(s)` distinction collapses cleanly into this shape.
    public struct Default: Sendable {
        /// Creates a tokenizer with default policy.
        @inlinable
        public init() {}

        /// Tokenizes a raw argv array into a normalized L1 token stream.
        ///
        /// - Parameter argv: The raw argv array (typically
        ///   `Array(CommandLine.arguments.dropFirst())` — program-name
        ///   prefix already removed).
        /// - Returns: The classified L1 token stream.
        /// - Throws: ``Command/Error`` wrapping an L2 tokenizer
        ///   diagnostic.
        public func tokenize(_ argv: [String]) throws(Command.Error) -> [Argument.Token] {
            var tokens: [Argument.Token] = []
            var byteOffset: Swift.Int = 0
            var afterEndOfOptions = false

            for (argvIndex, element) in argv.enumerated() {
                let elementByteCount = element.utf8.count
                let elementStart = Text.Position(_unchecked: Ordinal(Swift.UInt(byteOffset)))
                let elementEnd = Text.Position(
                    _unchecked: Ordinal(Swift.UInt(byteOffset + elementByteCount))
                )
                let elementRange = Text.Range(start: elementStart, end: elementEnd)
                defer { byteOffset += elementByteCount }

                // After --, everything is positional.
                if afterEndOfOptions {
                    tokens.append(.init(kind: .positional(element), range: elementRange))
                    continue
                }

                // -- end-of-options separator.
                if element == "--" {
                    tokens.append(.init(kind: .endOfOptions, range: elementRange))
                    afterEndOfOptions = true
                    continue
                }

                // GNU long-option shape (--name or --name=value).
                if element.hasPrefix("--"), element.count > 2 {
                    let afterDoubleDash = element.dropFirst(2)
                    if let equalsIndex = afterDoubleDash.firstIndex(of: "=") {
                        let name = Swift.String(afterDoubleDash[..<equalsIndex])
                        let value = Swift.String(afterDoubleDash[afterDoubleDash.index(after: equalsIndex)...])
                        // Two L1 tokens: .long(name) + .value(value), each sharing
                        // the source range (cheaper than computing sub-ranges; consumers
                        // distinguish via .kind, not by range).
                        tokens.append(.init(kind: .long(name), range: elementRange))
                        tokens.append(.init(kind: .value(value), range: elementRange))
                    } else {
                        let name = Swift.String(afterDoubleDash)
                        tokens.append(.init(kind: .long(name), range: elementRange))
                    }
                    continue
                }

                // POSIX 12.2 short-flag / cluster / value / operand: delegate
                // to L2 tokenizer per-element. The L2 tokenizer accepts a full
                // argv but we feed one element at a time so the per-element
                // token range we compute above matches the L2 emission.
                var oneElementArgv: [Swift.String] = [element]
                let l2Tokens: [IEEE_1003.UtilitySyntax.Token]
                do {
                    l2Tokens = try IEEE_1003.UtilitySyntax.Tokenizer().parse(&oneElementArgv)
                } catch {
                    throw .tokenizer(reason: "\(error)", argvIndex: argvIndex)
                }
                for l2Token in l2Tokens {
                    tokens.append(.init(kind: Self.map(l2Kind: l2Token.kind), range: elementRange))
                }
            }

            return tokens
        }

        /// Maps an L2 POSIX-shaped token kind to the L1 normalized kind.
        ///
        /// Per the L2-to-L1 hand-off table documented on ``Default``.
        @inlinable
        internal static func map(
            l2Kind: IEEE_1003.UtilitySyntax.Token.Kind
        ) -> Argument.Token.Kind {
            switch l2Kind {
            case .shortFlag(let character):
                return .shortCluster(Swift.String(character))

            case .shortValue(let string):
                return .value(string)

            case .shortCluster(let string):
                return .shortCluster(string)

            case .operand(let string):
                return .positional(string)

            case .endOfOptions:
                return .endOfOptions
            }
        }
    }
}
