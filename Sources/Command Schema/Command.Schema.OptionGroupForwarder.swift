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
    /// A forwarding visitor that flattens a fragment schema's nodes into
    /// parent-rooted parse entries.
    ///
    /// `OptionGroupForwarder<Root, G>` is the inner visitor used by
    /// ``Command/Schema/ParseVisitor`` when it encounters a
    /// ``Command/OptionGroup``. It walks the group's sub-schema (rooted
    /// on `G`) and accumulates ``Command/Schema/ParseVisitor`` entries
    /// whose apply closures chain through the outer
    /// `WritableKeyPath<Root, G>` so values land in the parent's
    /// fragment field.
    ///
    /// Each entry's apply closure follows the read-modify-write pattern:
    /// 1. Read the current fragment value from `root[keyPath: outer]`.
    /// 2. Apply the sub-node's value-parser to overwrite the fragment's
    ///    own field via `fragment[keyPath: inner]`.
    /// 3. Write the modified fragment back via `root[keyPath: outer]`.
    ///
    /// This avoids a `WritableKeyPath` chain construction and works
    /// uniformly across positionals, options, and flags.
    @usableFromInline
    internal struct OptionGroupForwarder<Root: Sendable, G: Sendable & Equatable>: Command.Schema.Visitor {
        @usableFromInline
        internal typealias Failure = Command.Error

        /// The outer keyPath from `Root` to the group's fragment value.
        @usableFromInline
        internal let outerKeyPath: WritableKeyPath<Root, G> & Sendable

        /// Positional entries accumulated during the sub-schema walk.
        @usableFromInline
        internal var positionals: [Command.Schema.ParseVisitor<Root>.PositionalEntry] = []

        /// Array-positional ("Many") entry, if any. At most one across
        /// the entire schema — the parent visitor's `visit(optionGroup:)`
        /// folds this into its own slot and rejects duplicates.
        @usableFromInline
        internal var positionalMany: Command.Schema.ParseVisitor<Root>.PositionalManyEntry?

        /// Option entries accumulated during the sub-schema walk.
        @usableFromInline
        internal var options: [Command.Schema.ParseVisitor<Root>.OptionEntry] = []

        /// Repeatable-option ("Many") entries accumulated during the
        /// sub-schema walk.
        @usableFromInline
        internal var optionManies: [Command.Schema.ParseVisitor<Root>.OptionManyEntry] = []

        /// Flag entries accumulated during the sub-schema walk.
        @usableFromInline
        internal var flags: [Command.Schema.ParseVisitor<Root>.FlagEntry] = []

        /// Count-flag entries accumulated during the sub-schema walk.
        @usableFromInline
        internal var flagCounts: [Command.Schema.ParseVisitor<Root>.FlagCountEntry] = []

        /// Inverted-flag entries accumulated during the sub-schema walk.
        @usableFromInline
        internal var flagInverteds: [Command.Schema.ParseVisitor<Root>.FlagInvertedEntry] = []

        /// Enumerable-flag entries accumulated during the sub-schema walk.
        @usableFromInline
        internal var flagEnumerables: [Command.Schema.ParseVisitor<Root>.FlagEnumerableEntry] = []

        @usableFromInline
        internal init(outerKeyPath: WritableKeyPath<Root, G> & Sendable) {
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
                    environmentVariable: option.declaration.environmentVariable
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
                let name = E.flagName(for: value).string
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
            // OptionGroups intentionally cannot host subcommand groups —
            // an option-group is a flat fragment of options/flags/positionals,
            // not a parent for a dispatch dimension. Schema authors should
            // declare subcommand groups at the parent command's schema
            // root, not inside fragments.
            throw .validationFailed(
                reason: "Command.OptionGroup cannot contain a Command.Subcommand.Group; "
                    + "declare the subcommand group at the parent command's schema."
            )
        }

        @usableFromInline
        internal mutating func visit<H: Sendable & Equatable>(
            optionGroup nested: Command.OptionGroup<G, H>
        ) throws(Command.Error) {
            // Nested option groups: walk the nested group's sub-schema
            // using a forwarder rooted on the inner fragment H, then
            // re-wrap each accumulated entry's apply closure to chain
            // through both the outer (Root → G) and the nested (G → H)
            // keyPaths.
            //
            // This stacked-closure approach avoids constructing a
            // `WritableKeyPath` chain via `appending(path:)` (which does
            // not propagate Sendable in Swift 6) — each chain step is
            // expressed via closure-level composition.
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
                        environmentVariable: entry.environmentVariable
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
