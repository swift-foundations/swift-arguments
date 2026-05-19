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

extension Command.Subcommand.Help {
    /// A help-text row collector for ``Command/OptionGroup`` sub-schemas
    /// in subcommand help rendering.
    ///
    /// Mirrors ``Command/Help/OptionGroupRowCollector`` exactly in shape;
    /// the two collectors duplicate because the `Command Schema` target
    /// cannot depend on `Command Help` (and vice-versa is fine but not
    /// needed). Schema authors interact with neither directly — the
    /// parent visitor invokes the appropriate collector via
    /// ``Command/Schema/Visitor/visit(optionGroup:)``.
    @usableFromInline
    internal struct OptionGroupRowCollector<G: Sendable & Equatable>: Command.Schema.Visitor {
        @usableFromInline
        internal typealias Failure = Never

        /// Optional seed value for the option-group fragment. Mirrors
        /// ``Command/HelpOptionGroupRowCollector``'s `initial` slot.
        @usableFromInline
        internal let initial: G?

        /// Accumulated rows in declaration order.
        @usableFromInline
        internal var rows: [Command.Subcommand.Help.Row] = []

        @usableFromInline
        internal init(initial: G? = nil) {
            self.initial = initial
        }

        @usableFromInline
        internal mutating func visit<V: Sendable & Equatable>(
            positional: Command.Positional<G, V>
        ) throws(Never) {
            let help = Command.Subcommand.HelpDefault.inject(
                positional.declaration.help,
                initial: initial,
                keyPath: positional.keyPath
            )
            rows.append(
                .positional(
                    name: positional.declaration.name,
                    valueName: positional.declaration.valueName,
                    help: help,
                    visibility: positional.declaration.visibility
                )
            )
        }

        @usableFromInline
        internal mutating func visit<V: Sendable & Equatable>(
            positionalMany: Command.Positional<G, V>.Many
        ) throws(Never) {
            let help = Command.Subcommand.HelpDefault.inject(
                positionalMany.declaration.help,
                initial: initial,
                keyPath: positionalMany.keyPath
            )
            rows.append(
                .positionalMany(
                    name: positionalMany.declaration.name,
                    valueName: positionalMany.declaration.valueName,
                    help: help,
                    visibility: positionalMany.declaration.visibility
                )
            )
        }

        @usableFromInline
        internal mutating func visit<V: Sendable & Equatable>(
            option: Command.Option<G, V>
        ) throws(Never) {
            let help = Command.Subcommand.HelpDefault.inject(
                option.declaration.help,
                initial: initial,
                keyPath: option.keyPath
            )
            rows.append(
                .option(
                    name: option.declaration.name,
                    valueName: option.declaration.valueName,
                    help: help,
                    visibility: option.declaration.visibility
                )
            )
        }

        @usableFromInline
        internal mutating func visit<V: Sendable & Equatable>(
            optionMany: Command.Option<G, V>.Many
        ) throws(Never) {
            let help = Command.Subcommand.HelpDefault.inject(
                optionMany.declaration.help,
                initial: initial,
                keyPath: optionMany.keyPath
            )
            rows.append(
                .optionMany(
                    name: optionMany.declaration.name,
                    valueName: optionMany.declaration.valueName,
                    help: help,
                    visibility: optionMany.declaration.visibility
                )
            )
        }

        @usableFromInline
        internal mutating func visit(flag: Command.Flag<G>) throws(Never) {
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
            let help = Command.Subcommand.HelpDefault.inject(
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
            if help.defaultDescription == nil, let initial {
                let value = initial[keyPath: flagInverted.keyPath]
                let renderedName = value ? flagInverted.trueName : flagInverted.falseName
                help = Argument.Help(
                    abstract: help.abstract,
                    discussion: help.discussion,
                    valueDescription: help.valueDescription,
                    defaultDescription: "--" + renderedName
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
            if help.defaultDescription == nil, let initial {
                let value = initial[keyPath: flagEnumerable.keyPath]
                let renderedName = E.flagName(for: value).string
                help = Argument.Help(
                    abstract: help.abstract,
                    discussion: help.discussion,
                    valueDescription: help.valueDescription,
                    defaultDescription: "--" + renderedName
                )
            }
            let cases: [Command.Subcommand.Help.EnumerableCase] = E.allCases.map { value in
                Command.Subcommand.Help.EnumerableCase(
                    name: E.flagName(for: value).string,
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
            // parse time; skip silently at render time.
        }

        @usableFromInline
        internal mutating func visit<H: Sendable & Equatable>(
            optionGroup nested: Command.OptionGroup<G, H>
        ) throws(Never) {
            // Nested option groups: recurse into the nested group's
            // sub-schema with a fresh row collector rooted on H. Rows
            // are appended in declaration order; visibility on the
            // nested group acts as an AND-mask.
            if nested.visibility == .hidden {
                return
            }
            let innerInitial: H? = initial.map { $0[keyPath: nested.keyPath] }
            var inner = Command.Subcommand.Help.OptionGroupRowCollector<H>(initial: innerInitial)
            nested.schema.accept(&inner)
            rows.append(contentsOf: inner.rows)
        }
    }
}
