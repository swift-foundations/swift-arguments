extension Command.Schema {

    @usableFromInline
    internal struct OptionGroupForwarder<Root: Sendable, G: Sendable & Equatable>: Command.Schema
            .Visitor
    {
        @usableFromInline
        internal typealias Failure = Command.Error

        @usableFromInline
        internal let outerKeyPath: any WritableKeyPath<Root, G> & Sendable

        @usableFromInline
        internal var positionals: [Command.Schema.ParseVisitor<Root>.PositionalEntry] = []

        @usableFromInline
        internal var positionalMany: Command.Schema.ParseVisitor<Root>.PositionalManyEntry?

        @usableFromInline
        internal var options: [Command.Schema.ParseVisitor<Root>.OptionEntry] = []

        @usableFromInline
        internal var optionManies: [Command.Schema.ParseVisitor<Root>.OptionManyEntry] = []

        @usableFromInline
        internal var flags: [Command.Schema.ParseVisitor<Root>.FlagEntry] = []

        @usableFromInline
        internal var flagCounts: [Command.Schema.ParseVisitor<Root>.FlagCountEntry] = []

        @usableFromInline
        internal var flagInverteds: [Command.Schema.ParseVisitor<Root>.FlagInvertedEntry] = []

        @usableFromInline
        internal var flagEnumerables: [Command.Schema.ParseVisitor<Root>.FlagEnumerableEntry] = []

        @usableFromInline
        internal init(outerKeyPath: any WritableKeyPath<Root, G> & Sendable) {
            self.outerKeyPath = outerKeyPath
        }

        @usableFromInline
        internal mutating func visit<V: Sendable & Equatable>(
            positional: Command.Positional<G, V>
        ) throws(Command.Error) {
            let outer = outerKeyPath
            let inner = positional.keyPath
            let parse = positional.parse
            positionals.append(
                Command.Schema.ParseVisitor<Root>.PositionalEntry(
                    name: positional.declaration.name,
                    apply: { value, root in
                        guard let parsed = parse(value) else { return false }
                        var fragment = root[keyPath: outer]
                        fragment[keyPath: inner] = parsed
                        root[keyPath: outer] = fragment
                        return true
                    }
                )
            )
        }

        @usableFromInline
        internal mutating func visit<V: Sendable & Equatable>(
            positionalMany: Command.Positional<G, V>.Many
        ) throws(Command.Error) {
            guard self.positionalMany == nil else {
                throw .validationFailed(
                    reason: "OptionGroup declares more than one Command.Positional.Many; "
                        + "at most one array-positional is permitted per schema."
                )
            }
            let outer = outerKeyPath
            let inner = positionalMany.keyPath
            let parse = positionalMany.parse
            self.positionalMany = Command.Schema.ParseVisitor<Root>.PositionalManyEntry(
                name: positionalMany.declaration.name,
                arity: positionalMany.declaration.arity,
                append: { value, root in
                    guard let parsed = parse(value) else { return false }
                    var fragment = root[keyPath: outer]
                    fragment[keyPath: inner].append(parsed)
                    root[keyPath: outer] = fragment
                    return true
                },
                count: { root in
                    root[keyPath: outer][keyPath: inner].count
                }
            )
        }

        @usableFromInline
        internal mutating func visit<V: Sendable & Equatable>(
            option: Command.Option<G, V>
        ) throws(Command.Error) {
            let outer = outerKeyPath
            let inner = option.keyPath
            let parse = option.parse
            options.append(
                Command.Schema.ParseVisitor<Root>.OptionEntry(
                    name: option.declaration.name,
                    apply: { value, root in
                        guard let parsed = parse(value) else { return false }
                        var fragment = root[keyPath: outer]
                        fragment[keyPath: inner] = parsed
                        root[keyPath: outer] = fragment
                        return true
                    },
                    environment: option.declaration.environment
                )
            )
        }

        @usableFromInline
        internal mutating func visit<V: Sendable & Equatable>(
            optionMany: Command.Option<G, V>.Many
        ) throws(Command.Error) {
            let outer = outerKeyPath
            let inner = optionMany.keyPath
            let parse = optionMany.parse
            optionManies.append(
                Command.Schema.ParseVisitor<Root>.OptionManyEntry(
                    name: optionMany.declaration.name,
                    arity: optionMany.declaration.arity,
                    append: { value, root in
                        guard let parsed = parse(value) else { return false }
                        var fragment = root[keyPath: outer]
                        fragment[keyPath: inner].append(parsed)
                        root[keyPath: outer] = fragment
                        return true
                    },
                    count: { root in
                        root[keyPath: outer][keyPath: inner].count
                    }
                )
            )
        }

        @usableFromInline
        internal mutating func visit(flag: Command.Flag<G>) throws(Command.Error) {
            let outer = outerKeyPath
            let inner = flag.keyPath
            flags.append(
                Command.Schema.ParseVisitor<Root>.FlagEntry(
                    name: flag.declaration.name,
                    apply: { root in
                        var fragment = root[keyPath: outer]
                        fragment[keyPath: inner] = true
                        root[keyPath: outer] = fragment
                    }
                )
            )
        }

        @usableFromInline
        internal mutating func visit(
            flagCount: Command.Flag<G>.Count
        ) throws(Command.Error) {
            let outer = outerKeyPath
            let inner = flagCount.keyPath
            flagCounts.append(
                Command.Schema.ParseVisitor<Root>.FlagCountEntry(
                    name: flagCount.declaration.name,
                    increment: { root in
                        var fragment = root[keyPath: outer]
                        fragment[keyPath: inner] += 1
                        root[keyPath: outer] = fragment
                    }
                )
            )
        }

        @usableFromInline
        internal mutating func visit(
            flagInverted: Command.Flag<G>.Inverted
        ) throws(Command.Error) {
            let outer = outerKeyPath
            let inner = flagInverted.keyPath
            flagInverteds.append(
                Command.Schema.ParseVisitor<Root>.FlagInvertedEntry(
                    trueName: flagInverted.trueName,
                    falseName: flagInverted.falseName,
                    apply: { value, root in
                        var fragment = root[keyPath: outer]
                        fragment[keyPath: inner] = value
                        root[keyPath: outer] = fragment
                    }
                )
            )
        }

        @usableFromInline
        internal mutating func visit<E: Argument.Flag.Enumerable>(
            flagEnumerable: Command.Flag<G>.Enumerable<E>
        ) throws(Command.Error) {
            let outer = outerKeyPath
            let inner = flagEnumerable.keyPath
            var casesByLongName: [String: @Sendable (inout Root) -> Void] = [:]
            for value in E.allCases {
                let name = E.name(for: value).string
                let captured = value
                casesByLongName[name] = { root in
                    var fragment = root[keyPath: outer]
                    fragment[keyPath: inner] = captured
                    root[keyPath: outer] = fragment
                }
            }
            flagEnumerables.append(
                Command.Schema.ParseVisitor<Root>.FlagEnumerableEntry(
                    casesByLongName: casesByLongName
                )
            )
        }

        @usableFromInline
        internal mutating func visit(
            subcommandGroup: Command.Subcommand.Group<G>
        ) throws(Command.Error) {

            throw .validationFailed(
                reason: "Command.OptionGroup cannot contain a Command.Subcommand.Group; "
                    + "declare the subcommand group at the parent command's schema."
            )
        }

        @usableFromInline
        internal mutating func visit<H: Sendable & Equatable>(
            optionGroup nested: Command.OptionGroup<G, H>
        ) throws(Command.Error) {

            var inner = Command.Schema.OptionGroupForwarder<G, H>(
                outerKeyPath: nested.keyPath
            )
            try nested.schema.accept(&inner)
            let outer = outerKeyPath
            for entry in inner.positionals {
                let innerApply = entry.apply
                positionals.append(
                    Command.Schema.ParseVisitor<Root>.PositionalEntry(
                        name: entry.name,
                        apply: { value, root in
                            var fragment = root[keyPath: outer]
                            let success = innerApply(value, &fragment)
                            root[keyPath: outer] = fragment
                            return success
                        }
                    )
                )
            }
            if let manyEntry = inner.positionalMany {
                guard self.positionalMany == nil else {
                    throw .validationFailed(
                        reason: "Nested OptionGroup declares more than one "
                            + "Command.Positional.Many; at most one array-positional "
                            + "is permitted per schema."
                    )
                }
                let innerAppend = manyEntry.append
                let innerCount = manyEntry.count
                self.positionalMany = Command.Schema.ParseVisitor<Root>.PositionalManyEntry(
                    name: manyEntry.name,
                    arity: manyEntry.arity,
                    append: { value, root in
                        var fragment = root[keyPath: outer]
                        let success = innerAppend(value, &fragment)
                        root[keyPath: outer] = fragment
                        return success
                    },
                    count: { root in
                        innerCount(root[keyPath: outer])
                    }
                )
            }
            for entry in inner.options {
                let innerApply = entry.apply
                options.append(
                    Command.Schema.ParseVisitor<Root>.OptionEntry(
                        name: entry.name,
                        apply: { value, root in
                            var fragment = root[keyPath: outer]
                            let success = innerApply(value, &fragment)
                            root[keyPath: outer] = fragment
                            return success
                        },
                        environment: entry.environment
                    )
                )
            }
            for entry in inner.optionManies {
                let innerAppend = entry.append
                let innerCount = entry.count
                optionManies.append(
                    Command.Schema.ParseVisitor<Root>.OptionManyEntry(
                        name: entry.name,
                        arity: entry.arity,
                        append: { value, root in
                            var fragment = root[keyPath: outer]
                            let success = innerAppend(value, &fragment)
                            root[keyPath: outer] = fragment
                            return success
                        },
                        count: { root in
                            innerCount(root[keyPath: outer])
                        }
                    )
                )
            }
            for entry in inner.flags {
                let innerApply = entry.apply
                flags.append(
                    Command.Schema.ParseVisitor<Root>.FlagEntry(
                        name: entry.name,
                        apply: { root in
                            var fragment = root[keyPath: outer]
                            innerApply(&fragment)
                            root[keyPath: outer] = fragment
                        }
                    )
                )
            }
            for entry in inner.flagCounts {
                let innerIncrement = entry.increment
                flagCounts.append(
                    Command.Schema.ParseVisitor<Root>.FlagCountEntry(
                        name: entry.name,
                        increment: { root in
                            var fragment = root[keyPath: outer]
                            innerIncrement(&fragment)
                            root[keyPath: outer] = fragment
                        }
                    )
                )
            }
            for entry in inner.flagInverteds {
                let innerApply = entry.apply
                flagInverteds.append(
                    Command.Schema.ParseVisitor<Root>.FlagInvertedEntry(
                        trueName: entry.trueName,
                        falseName: entry.falseName,
                        apply: { value, root in
                            var fragment = root[keyPath: outer]
                            innerApply(value, &fragment)
                            root[keyPath: outer] = fragment
                        }
                    )
                )
            }
            for entry in inner.flagEnumerables {
                let innerCases = entry.casesByLongName
                var rewrappedCases: [String: @Sendable (inout Root) -> Void] = [:]
                for (name, innerApply) in innerCases {
                    rewrappedCases[name] = { root in
                        var fragment = root[keyPath: outer]
                        innerApply(&fragment)
                        root[keyPath: outer] = fragment
                    }
                }
                flagEnumerables.append(
                    Command.Schema.ParseVisitor<Root>.FlagEnumerableEntry(
                        casesByLongName: rewrappedCases
                    )
                )
            }
        }
    }
}
