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

extension Command.Flag {
    /// A KeyPath-bound enumerable-flag declaration.
    ///
    /// `Command.Flag.Enumerable` is the enum-of-flags sibling of
    /// ``Command/Flag`` for argv layouts where one of a fixed set of
    /// mutually exclusive long options selects a case of an enum, e.g.
    /// `mycli --add` vs. `mycli --multiply` writing different cases of
    /// an `Operation` enum to the bound field. The institute analog of
    /// swift-argument-parser's `EnumerableFlag` protocol.
    ///
    /// A typical call site:
    ///
    /// ```swift
    /// enum Operation: Argument.Flag.Enumerable {
    ///     case add, multiply
    ///     static func name(for value: Self) -> Argument.Name.Long {
    ///         switch value {
    ///         case .add: return .literal("add")
    ///         case .multiply: return .literal("multiply")
    ///         }
    ///     }
    ///     static func help(for value: Self) -> Argument.Help {
    ///         switch value {
    ///         case .add: return .init(abstract: "Add operands.")
    ///         case .multiply: return .init(abstract: "Multiply operands.")
    ///         }
    ///     }
    /// }
    ///
    /// Command.Flag<MyRoot>.Enumerable<Operation>(\.operation,
    ///     help: .init(abstract: "Operation selector."))
    /// ```
    ///
    /// ## Mutual exclusivity
    ///
    /// Each enum case registers its own long-option name. When multiple
    /// cases appear on argv, the rightmost occurrence wins — there is
    /// no `FlagExclusivity` parameter in v1; the last-wins semantics is
    /// fixed.
    ///
    /// ## Initial value
    ///
    /// The bound field's initial value supplies the selection when no
    /// argv case matches. Schemas requiring a mandatory selection
    /// validate the resulting value at finalization time outside this
    /// declaration.
    public struct Enumerable<E: Argument.Flag.Enumerable>: Sendable
    where Root: Sendable {
        /// The KeyPath into `Root` where the matched enum case is
        /// written on argv match.
        public let keyPath: WritableKeyPath<Root, E> & Sendable

        /// Whether the cases' long options appear in help.
        public let visibility: Argument.Visibility

        /// Group-level documentation rendered above the per-case rows.
        public let help: Argument.Help

        /// Creates a KeyPath-bound enumerable-flag declaration.
        ///
        /// - Parameters:
        ///   - keyPath: The enum field this flag writes to on argv match.
        ///   - visibility: Whether the cases' long options appear in
        ///     help. Defaults to ``Argument/Visibility/visible``.
        ///   - help: Group-level documentation rendered above the
        ///     per-case rows. Defaults to empty.
        @inlinable
        public init(
            _ keyPath: WritableKeyPath<Root, E> & Sendable,
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init()
        ) {
            self.keyPath = keyPath
            self.visibility = visibility
            self.help = help
        }
    }
}
