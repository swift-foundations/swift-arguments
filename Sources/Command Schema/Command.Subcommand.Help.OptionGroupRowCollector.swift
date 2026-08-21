extension Command.Subcommand.Help {

    @usableFromInline
    internal struct OptionGroupRowCollector<G: Sendable & Equatable>: Command.Schema.Visitor {
        @usableFromInline
        internal typealias Failure = Never

        @usableFromInline
        internal let initial: G?

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
            let help = Command.Subcommand.HelpDefault.inject(
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
            let help = Command.Subcommand.HelpDefault.inject(
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
            let help = Command.Subcommand.HelpDefault.inject(
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
            let cases: [Command.Subcommand.Help.EnumerableCase] = E.allCases.map { value in
                Command.Subcommand.Help.EnumerableCase(
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

        }

        @usableFromInline
        internal mutating func visit<H: Sendable & Equatable>(
            optionGroup nested: Command.OptionGroup<G, H>
        ) throws(Never) {

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
