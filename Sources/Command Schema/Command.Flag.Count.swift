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
    /// A KeyPath-bound count-flag declaration.
    ///
    /// `Command.Flag.Count` is the integer-counter sibling of
    /// ``Command/Flag`` for argv layouts where each occurrence of the
    /// flag increments a `WritableKeyPath<Root, Int>` target — the
    /// canonical `-vvv` verbosity-stacking pattern.
    ///
    /// A typical call site:
    ///
    /// ```swift
    /// Command.Flag<MyRoot>.Count(\.verbosity,
    ///     name: .shortLiteral("v"),
    ///     help: .init(abstract: "Increase verbosity (repeatable)."))
    /// ```
    ///
    /// ## Short-cluster behaviour
    ///
    /// When the flag carries a short name `v`, the schema parser
    /// recognises both `-v -v -v` (three separate tokens) and `-vvv`
    /// (a single short cluster). Each character in the cluster
    /// contributes one increment to the bound counter. Long-form
    /// repetition (`--verbose --verbose --verbose`) is also supported;
    /// each occurrence increments by one.
    ///
    /// ## Initial value
    ///
    /// The bound field's initial value (typically `0`) supplies the
    /// starting counter; the parse visitor adds one for each occurrence.
    public struct Count: Sendable where Root: Sendable {
        /// The KeyPath into `Root` where the counter increments on each
        /// occurrence of the flag.
        public let keyPath: WritableKeyPath<Root, Int> & Sendable

        /// The L1 declaration carrying name / arity / visibility / help.
        ///
        /// The declaration's arity is fixed to ``Argument/Arity/count``
        /// at construction; consumers do not override it.
        public let declaration: Argument.Flag

        /// Creates a KeyPath-bound count-flag declaration.
        ///
        /// - Parameters:
        ///   - keyPath: The Int field this flag increments on each
        ///     occurrence.
        ///   - name: The flag name (short / long / both).
        ///   - visibility: Whether the flag appears in help. Defaults to
        ///     ``Argument/Visibility/visible``.
        ///   - help: Documentation. Defaults to empty.
        @inlinable
        public init(
            _ keyPath: WritableKeyPath<Root, Int> & Sendable,
            name: Argument.Name,
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init()
        ) {
            self.keyPath = keyPath
            self.declaration = Argument.Flag(
                name: name,
                arity: .count,
                visibility: visibility,
                help: help
            )
        }
    }
}
