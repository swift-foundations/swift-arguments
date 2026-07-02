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
    /// A help-text row collector for ``Command/OptionGroup`` sub-schemas.
    ///
    /// `Command.HelpOptionGroupRowCollector<G>` walks a
    /// ``Command/Schema/Definition`` rooted on a fragment type `G` and
    /// accumulates ``Command/HelpRow`` entries in declaration order.
    /// The parent ``Command/Help/Visitor`` splices these rows directly
    /// into its own `rows` list when handling
    /// ``Command/Schema/Visitor/visit(optionGroup:)`` — the shared
    /// non-generic ``Command/HelpRow`` type means no per-Root
    /// re-wrapping is required.
    ///
    /// Subcommand bindings declared inside an option group are
    /// intentionally a no-op at the row-collection layer: the parse
    /// visitor rejects nested subcommand groups structurally
    /// (``Command/Error/validationFailed(reason:)``), so the help
    /// visitor likewise omits them rather than rendering a SUBCOMMANDS
    /// section that the parser would refuse to dispatch.
    ///
    /// Compound naming is `@usableFromInline internal` — strictly an
    /// implementation detail.
    @usableFromInline
    internal struct HelpOptionGroupRowCollector<G: Sendable & Equatable>: Command.Schema.Visitor {
        @usableFromInline
        internal typealias Failure = Never

        /// Optional seed instance for the option-group fragment.
        ///
        /// When non-`nil` the parent visitor sliced its own `initial` via
        /// the group's outer key path before constructing this
        /// collector. Each visit method routes through
        /// ``Command/HelpDefault/inject(_:initial:keyPath:)`` so the
        /// auto-derivation logic matches the top-level Visitor.
        @usableFromInline
        internal let initial: G?

        /// Accumulated rows in declaration order.
        @usableFromInline
        internal var rows: [Command.HelpRow] = []

        @usableFromInline
        internal init(initial: G? = nil) {
            self.initial = initial
        }

        @usableFromInline
        internal mutating func visit<V: Sendable & Equatable>(
            positional: Command.Positional<G, V>
        ) throws(Never) {
            let help = Command.HelpDefault.inject(
                positional.declaration.help,
                initial: initial,
                keyPath: positional.keyPath
            )
            rows.append(
                .positional(
                    name: positional.declaration.name,
                    placeholder: positional.declaration.placeholder,
                    help: help,
                    visibility: positional.declaration.visibility
                )
            )
        }

        @usableFromInline
        internal mutating func visit<V: Sendable & Equatable>(
            positionalMany: Command.Positional<G, V>.Many
        ) throws(Never) {
            let help = Command.HelpDefault.inject(
                positionalMany.declaration.help,
                initial: initial,
                keyPath: positionalMany.keyPath
            )
            rows.append(
                .positionalMany(
                    name: positionalMany.declaration.name,
                    placeholder: positionalMany.declaration.placeholder,
                    help: help,
                    visibility: positionalMany.declaration.visibility
                )
            )
        }

        @usableFromInline
        internal mutating func visit<V: Sendable & Equatable>(
            option: Command.Option<G, V>
        ) throws(Never) {
            let help = Command.HelpDefault.inject(
                option.declaration.help,
                initial: initial,
                keyPath: option.keyPath
            )
            rows.append(
                .option(
                    name: option.declaration.name,
                    placeholder: option.declaration.placeholder,
                    help: help,
                    visibility: option.declaration.visibility
                )
            )
        }

        @usableFromInline
        internal mutating func visit<V: Sendable & Equatable>(
            optionMany: Command.Option<G, V>.Many
        ) throws(Never) {
            let help = Command.HelpDefault.inject(
                optionMany.declaration.help,
                initial: initial,
                keyPath: optionMany.keyPath
            )
            rows.append(
                .optionMany(
                    name: optionMany.declaration.name,
                    placeholder: optionMany.declaration.placeholder,
                    help: help,
                    visibility: optionMany.declaration.visibility
                )
            )
        }

        @usableFromInline
        internal mutating func visit(flag: Command.Flag<G>) throws(Never) {
            // Bool flags: present/absent semantics — no auto-default.
            rows.append(
                .flag(
                    name: flag.declaration.name,
                    help: flag.declaration.help,
                    visibility: flag.declaration.visibility
                )
            )
        }

        @usableFromInline
        internal mutating func visit(
            flagCount: Command.Flag<G>.Count
        ) throws(Never) {
            let help = Command.HelpDefault.inject(
                flagCount.declaration.help,
                initial: initial,
                keyPath: flagCount.keyPath
            )
            rows.append(
                .flagCount(
                    name: flagCount.declaration.name,
                    help: help,
                    visibility: flagCount.declaration.visibility
                )
            )
        }

        @usableFromInline
        internal mutating func visit(
            flagInverted: Command.Flag<G>.Inverted
        ) throws(Never) {
            var help = flagInverted.help
            if help.defaults == nil, let initial {
                let value = initial[keyPath: flagInverted.keyPath]
                let renderedName = value ? flagInverted.trueName : flagInverted.falseName
                help = Argument.Help(
                    abstract: help.abstract,
                    discussion: help.discussion,
                    placeholder: help.placeholder,
                    defaults: "--" + renderedName
                )
            }
            rows.append(
                .flagInverted(
                    trueName: flagInverted.trueName,
                    falseName: flagInverted.falseName,
                    help: help,
                    visibility: flagInverted.visibility
                )
            )
        }

        @usableFromInline
        internal mutating func visit<E: Argument.Flag.Enumerable>(
            flagEnumerable: Command.Flag<G>.Enumerable<E>
        ) throws(Never) {
            var help = flagEnumerable.help
            if help.defaults == nil, let initial {
                let value = initial[keyPath: flagEnumerable.keyPath]
                let renderedName = E.name(for: value).string
                help = Argument.Help(
                    abstract: help.abstract,
                    discussion: help.discussion,
                    placeholder: help.placeholder,
                    defaults: "--" + renderedName
                )
            }
            let cases: [Command.HelpEnumerableCase] = E.allCases.map { value in
                Command.HelpEnumerableCase(
                    name: E.name(for: value).string,
                    help: E.help(for: value)
                )
            }
            rows.append(
                .flagEnumerable(
                    cases: cases,
                    help: help,
                    visibility: flagEnumerable.visibility
                )
            )
        }

        @usableFromInline
        internal mutating func visit(
            subcommandGroup: Command.Subcommand.Group<G>
        ) throws(Never) {
            // Subcommand groups inside an option group are rejected at
            // parse time (see Command.Schema.OptionGroupForwarder); we
            // silently skip them at render time as well rather than
            // rendering a SUBCOMMANDS section that the parser would
            // refuse to dispatch.
        }

        @usableFromInline
        internal mutating func visit<H: Sendable & Equatable>(
            optionGroup nested: Command.OptionGroup<G, H>
        ) throws(Never) {
            // Nested option groups: recurse into the nested group's
            // sub-schema with a fresh row collector rooted on H. Rows
            // are appended in declaration order; visibility on the
            // nested group acts as an AND-mask, matching the parent
            // visitor's policy.
            if nested.visibility == .hidden {
                return
            }
            let innerInitial: H? = initial.map { $0[keyPath: nested.keyPath] }
            var inner = Command.HelpOptionGroupRowCollector<H>(initial: innerInitial)
            nested.schema.accept(&inner)
            rows.append(contentsOf: inner.rows)
        }
    }
}
