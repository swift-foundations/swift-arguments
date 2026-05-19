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
    /// A KeyPath-bound declaration that splats a sub-schema's nodes into
    /// the parent schema.
    ///
    /// `Command.OptionGroup<Root, G>` is the L3 binding-aware analogue of
    /// swift-argument-parser's `@OptionGroup`. It lets schema authors
    /// factor a shared set of options into a fragment struct `G` (with
    /// its own ``Command/Schema/Definition``) and reuse the fragment
    /// across multiple parent commands without redeclaring the options.
    ///
    /// ## Example
    ///
    /// ```swift
    /// /// Shared options used by every git subcommand.
    /// struct SharedOptions: Sendable, Equatable {
    ///     var root: String = "."
    ///     static let schema: Command.Schema.Definition<SharedOptions> = .init {
    ///         Command.Option(
    ///             \.root,
    ///             name: .longLiteral("root"),
    ///             help: .init(abstract: "Repository root directory.")
    ///         )
    ///     }
    /// }
    ///
    /// struct GitClone: Command.`Protocol`, Equatable {
    ///     var options: SharedOptions = .init()
    ///     var url: String = ""
    ///
    ///     static var schema: Command.Schema.Definition<Self> {
    ///         Command.Schema.Definition<Self> {
    ///             Command.OptionGroup(\.options, schema: SharedOptions.schema)
    ///             Command.Positional(\.url, name: "url")
    ///         }
    ///     }
    ///     // ...
    /// }
    /// ```
    ///
    /// ## Semantics
    ///
    /// At parse time the sub-schema's nodes are walked as if they were
    /// declared directly on `Root` — each sub-node's value is written
    /// through the chained keypath
    /// (`Root.keyPath.appending(subNode.keyPath)`). Help-text emission
    /// inlines the sub-schema's option rows into the parent's OPTIONS
    /// section in declaration order.
    ///
    /// ## Visibility
    ///
    /// The group's `visibility` controls whether its options appear in
    /// the parent's `--help` output. A `.hidden` group still parses
    /// argv values but suppresses the rows. Per-sub-node visibility
    /// declared on the fragment's schema is honored independently —
    /// the parent's visibility is an AND-mask, not an override.
    ///
    /// - Note: `G` is constrained `Sendable & Equatable` to match the
    ///   value-type constraints of ``Command/Option`` and
    ///   ``Command/Positional`` — the same generics that downstream
    ///   visitors expect to dispatch over. `G` is NOT required to
    ///   conform to ``Command/Protocol``: it is a fragment-bag, not a
    ///   command (no `run()` body, no configuration).
    public struct OptionGroup<Root, G>: Sendable
    where Root: Sendable, G: Sendable & Equatable {
        /// The KeyPath into `Root` where the group's nested fragment lives.
        public let keyPath: WritableKeyPath<Root, G> & Sendable

        /// The sub-schema describing the fragment's option / flag / positional
        /// declarations rooted on `G`.
        public let schema: Command.Schema.Definition<G>

        /// Whether the group's options appear in the parent's help output.
        ///
        /// `.hidden` suppresses the group's row contributions during
        /// help-text rendering but still parses argv values into the
        /// fragment. Per-sub-node visibility on the fragment's own
        /// schema is honored independently — this flag is an
        /// AND-mask, not an override.
        public let visibility: Argument.Visibility

        /// Creates an option-group declaration that splats the fragment's
        /// schema into the parent.
        ///
        /// - Parameters:
        ///   - keyPath: The Root field where the fragment value lives.
        ///   - schema: The fragment's own schema definition.
        ///   - visibility: Whether the group's options appear in help.
        ///     Defaults to ``Argument/Visibility/visible``.
        @inlinable
        public init(
            _ keyPath: WritableKeyPath<Root, G> & Sendable,
            schema: Command.Schema.Definition<G>,
            visibility: Argument.Visibility = .visible
        ) {
            self.keyPath = keyPath
            self.schema = schema
            self.visibility = visibility
        }
    }
}
