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

extension Command.Schema {
    /// A visitor over a ``Command/Schema/Definition``'s bound nodes.
    ///
    /// Implementations receive value-typed dispatch from each
    /// ``Command/Schema/Node`` (via `Node.accept(_:)`) and produce
    /// some artifact: help text (``Command/Help``), completion script
    /// (v2+), manpage (v2+), or a parse configuration. The visitor
    /// protocol is the structural anchor for the §2.2 bidirectionality
    /// — the same schema instance drives parse and emit directions.
    ///
    /// ## Failure
    ///
    /// `Failure` defaults to `Never` (pure-text emitters typically can't
    /// fail). Visitors that compose with throwing infrastructure (e.g.,
    /// a parser-config builder that validates cross-field constraints
    /// at build time) override `Failure` to a domain-specific
    /// `Swift.Error`.
    public protocol Visitor<Root> {
        /// The Root command struct whose schema is being visited.
        associatedtype Root: Sendable

        /// The error this visitor surfaces. Defaults to `Never`.
        associatedtype Failure: Swift.Error = Never

        /// Visit a KeyPath-bound positional declaration.
        ///
        /// The value-type constraint is `Sendable & Equatable` only —
        /// ``Argument/Codable`` is required by the standard
        /// ``Command/Positional`` initializer but not by the
        /// `transform:` overload, so visit methods may receive
        /// declarations bound to non-``Argument/Codable`` value types.
        /// Visitors consume the type-erased
        /// ``Command/Positional/parse`` closure rather than calling
        /// ``Argument/Codable/init(argument:)`` directly.
        mutating func visit<V: Sendable & Equatable>(
            positional: Command.Positional<Root, V>
        ) throws(Failure)

        /// Visit a KeyPath-bound array-positional declaration.
        ///
        /// ``Command/Positional/Many`` binds `[V]` rather than `V` and
        /// appends each consumed positional value to the bound array. The
        /// declaration's ``Argument/Arity`` governs the accepted count.
        /// As with ``visit(positional:)``, the value-type constraint is
        /// `Sendable & Equatable` only.
        mutating func visit<V: Sendable & Equatable>(
            positionalMany: Command.Positional<Root, V>.Many
        ) throws(Failure)

        /// Visit a KeyPath-bound option declaration.
        ///
        /// The value-type constraint is `Sendable & Equatable` only —
        /// ``Argument/Codable`` is required by the standard
        /// ``Command/Option`` initializer but not by the `transform:`
        /// overload.
        mutating func visit<V: Sendable & Equatable>(
            option: Command.Option<Root, V>
        ) throws(Failure)

        /// Visit a KeyPath-bound array-option declaration.
        ///
        /// ``Command/Option/Many`` binds `[V]` rather than `V`; each
        /// occurrence of the option appends one parsed value to the
        /// bound array. As with ``visit(option:)``, the value-type
        /// constraint is `Sendable & Equatable` only.
        mutating func visit<V: Sendable & Equatable>(
            optionMany: Command.Option<Root, V>.Many
        ) throws(Failure)

        /// Visit a KeyPath-bound boolean-flag declaration.
        mutating func visit(flag: Command.Flag<Root>) throws(Failure)

        /// Visit a KeyPath-bound count-flag declaration.
        ///
        /// ``Command/Flag/Count`` binds `Int` rather than `Bool`; each
        /// occurrence increments the bound counter. Supports both long
        /// (`-v -v -v`) and short-cluster (`-vvv`) forms.
        mutating func visit(flagCount: Command.Flag<Root>.Count) throws(Failure)

        /// Visit a KeyPath-bound inverted boolean-flag declaration.
        ///
        /// ``Command/Flag/Inverted`` registers two long-option names —
        /// the "true" form and the "false" form per its
        /// ``Command/Flag/Inverted/Inversion`` strategy — and writes the
        /// appropriate value to the bound `Bool` field on argv match.
        mutating func visit(flagInverted: Command.Flag<Root>.Inverted) throws(Failure)

        /// Visit a KeyPath-bound enumerable-flag declaration.
        ///
        /// ``Command/Flag/Enumerable`` registers one long-option name per
        /// enum case (mutually exclusive — last-wins on argv) and writes
        /// the selected case to the bound `E` field.
        mutating func visit<E: Argument.Flag.Enumerable>(
            flagEnumerable: Command.Flag<Root>.Enumerable<E>
        ) throws(Failure)

        /// Visit a sum-type subcommand group.
        ///
        /// The group carries a heterogeneous list of
        /// ``Command/Subcommand/Binding`` instances; the parser
        /// dispatches on the first non-flag argv element by matching
        /// against each binding's `name` / `aliases`.
        mutating func visit(subcommandGroup: Command.Subcommand.Group<Root>) throws(Failure)

        /// Visit a KeyPath-bound option-group declaration.
        ///
        /// `Command.OptionGroup<Root, G>` carries a sub-schema rooted on
        /// a fragment type `G`. The visitor is responsible for walking
        /// the sub-schema's nodes and chaining their key-paths through
        /// the group's outer `WritableKeyPath<Root, G>` so values land in
        /// the parent's `G`-typed field.
        ///
        /// Implementations typically dispatch a sub-visit pass over the
        /// fragment's schema; the schema-walk infrastructure recovers
        /// the static value type of each sub-node at its own
        /// `visit(...)` call site.
        mutating func visit<G: Sendable & Equatable>(
            optionGroup: Command.OptionGroup<Root, G>
        ) throws(Failure)
    }
}
