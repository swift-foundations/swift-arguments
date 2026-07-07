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

extension Command.Subcommand {
    /// One sum-type subcommand binding.
    ///
    /// `Command.Subcommand.Case<Root, Sub>` is the L3 binding-aware
    /// analogue of L1's ``Argument/Subcommand`` declaration — pairing a
    /// CLI subcommand name with a `Sub` command type and the case-wrapping
    /// closure that lifts a parsed `Sub` value into the `Root` sum-type's
    /// matching enum case.
    ///
    /// The name `Case` mirrors the sum-type semantics: each
    /// `Command.Subcommand.Case` corresponds to one case of the `Root`
    /// enum.
    ///
    /// ## Example
    ///
    /// ```swift
    /// enum Git: Command.`Protocol` {
    ///     case clone(Clone)
    ///     case status(Status)
    ///
    ///     static var schema: Command.Schema.Definition<Self> {
    ///         Command.Schema.Definition {
    ///             Command.Subcommand.Group {
    ///                 Command.Subcommand.Case("clone", initial: Clone.init, map: Git.clone)
    ///                 Command.Subcommand.Case("status", initial: Status.init, map: Git.status)
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## Type parameters
    ///
    /// - `Root`: The parent command (typically a sum-type `enum`).
    /// - `Sub`: The sub-command this case dispatches to; carries its
    ///   own ``Command/Schema/Definition`` via ``Command/Protocol``.
    public struct Case<Root, Sub>: Sendable
    where Root: Sendable, Sub: Command.`Protocol` {
        /// The CLI subcommand name (such as `"clone"`).
        public let name: String

        /// Alternative names this subcommand also responds to (such as `["c"]`).
        public let aliases: [String]

        /// Whether this subcommand appears in help text.
        public let visibility: Argument.Visibility

        /// Documentation for this subcommand.
        public let help: Argument.Help

        /// Whether this case is the default subcommand.
        ///
        /// When `true`, the parse visitor dispatches this case when argv
        /// supplies no subcommand name (argv is empty after root-level
        /// option / flag consumption). At most one case per Group may
        /// carry `isDefault = true`; the
        /// ``Command/Subcommand/Group/Builder`` enforces uniqueness at
        /// schema-construction time.
        ///
        /// Set this flag via the ``default`` modifier:
        /// ```swift
        /// Command.Subcommand.Case("list", initial: List.init, map: Git.list).default
        /// ```
        public let isDefault: Bool

        /// Produces a seed `Sub` value for the sub-parse pass. Defaults
        /// in `Sub`'s memberwise init supply the unwritten fields.
        public let initial: @Sendable () -> Sub

        /// Wraps a parsed `Sub` value into the matching `Root` enum case
        /// (such as `Git.clone`).
        public let map: @Sendable (Sub) -> Root

        /// Creates a sum-type subcommand case.
        ///
        /// - Parameters:
        ///   - name: The CLI subcommand name.
        ///   - aliases: Alternative names. Defaults to `[]`.
        ///   - visibility: Whether this subcommand appears in help. Defaults
        ///     to `.visible`.
        ///   - help: Documentation. Defaults to empty.
        ///   - isDefault: Whether this case is dispatched when argv supplies
        ///     no subcommand name. Defaults to `false`. Prefer the fluent
        ///     ``default`` modifier at the call site.
        ///   - initial: A seed factory for the sub-parse pass.
        ///   - map: The case-wrapping closure from `Sub` to `Root`.
        @inlinable
        public init(
            _ name: String,
            aliases: [String] = [],
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init(),
            isDefault: Bool = false,
            initial: @escaping @Sendable () -> Sub,
            map: @escaping @Sendable (Sub) -> Root
        ) {
            self.name = name
            self.aliases = aliases
            self.visibility = visibility
            self.help = help
            self.isDefault = isDefault
            self.initial = initial
            self.map = map
        }
    }
}

extension Command.Subcommand.Case {
    /// Marks this case as the default subcommand, dispatched when argv
    /// supplies no subcommand name.
    ///
    /// The fluent shape lets schemas declare a default with a trailing
    /// modifier:
    ///
    /// ```swift
    /// Command.Subcommand.Group {
    ///     Command.Subcommand.Case("list", initial: List.init, map: Git.list).default
    ///     Command.Subcommand.Case("clone", initial: Clone.init, map: Git.clone)
    /// }
    /// ```
    ///
    /// At most one case per Group may carry the default flag. The
    /// ``Command/Subcommand/Group/Builder`` enforces uniqueness when the
    /// group is constructed.
    ///
    /// `default` is a reserved word in Swift; the property is written
    /// with backticks at the declaration site. Callers write
    /// ``\\.default`` without backticks (or `.default` when chained on a
    /// freshly constructed case).
    public var `default`: Self {
        Self(
            name,
            aliases: aliases,
            visibility: visibility,
            help: help,
            isDefault: true,
            initial: initial,
            map: map
        )
    }
}
