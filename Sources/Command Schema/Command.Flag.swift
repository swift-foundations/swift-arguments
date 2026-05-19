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

extension Command {
    /// A KeyPath-bound boolean-flag declaration.
    ///
    /// `Command.Flag<Root>` is the L3 binding-aware wrapper over the L1
    /// ``Argument/Flag`` declaration. A flag writes `true` to a `Bool`
    /// Root field when the flag's name appears in argv; absence of the
    /// flag leaves the Root field at its declared default (typically
    /// `false`).
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Inside Repeat.schema:
    /// Command.Flag(\.counter, name: .long("counter"),
    ///              help: .init(abstract: "Include a counter."))
    /// ```
    public struct Flag<Root>: Sendable where Root: Sendable {
        /// Public re-export of the outer `Root` generic param under
        /// a different identifier so nested types (``Flag/Enumerable``)
        /// can express their Schema.Node `Root` associated-type binding
        /// without tripping Swift's circular-typealias detection. The
        /// alternative — renaming `Flag`'s generic param to a non-`Root`
        /// identifier — would require every consumer-visible signature
        /// to change. Consumers should NOT reference this typealias
        /// directly; use ``Flag/Root`` (the natural generic-parameter
        /// name) at call sites. See ``Flag/Enumerable``'s
        /// ``Command/Schema/Node`` conformance for the lone usage.
        public typealias BoundRoot = Root

        /// The KeyPath into `Root` where presence of the flag writes `true`.
        public let keyPath: WritableKeyPath<Root, Bool> & Sendable

        /// The L1 declaration carrying name / arity / visibility / help.
        public let declaration: Argument.Flag

        /// Creates a KeyPath-bound flag declaration.
        ///
        /// - Parameters:
        ///   - keyPath: The Bool field this flag writes to.
        ///   - name: The flag name (short / long / both).
        ///   - arity: How the flag is counted. Defaults to `.atMost(1)`.
        ///   - visibility: Whether the flag appears in help. Defaults to
        ///     `.visible`.
        ///   - help: Documentation. Defaults to empty.
        @inlinable
        public init(
            _ keyPath: WritableKeyPath<Root, Bool> & Sendable,
            name: Argument.Name,
            arity: Argument.Arity = .atMost(1),
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init()
        ) {
            self.keyPath = keyPath
            self.declaration = Argument.Flag(
                name: name,
                arity: arity,
                visibility: visibility,
                help: help
            )
        }
    }
}
