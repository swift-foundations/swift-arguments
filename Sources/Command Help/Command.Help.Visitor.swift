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

extension Command.Help {
    /// The visitor that walks a ``Command/Schema/Definition`` and
    /// accumulates the entries needed to render help text.
    ///
    /// `Visitor` collects rows during the schema walk; ``render()`` then
    /// composes the formatted help text in the canonical
    /// swift-argument-parser layout. The two-pass shape lets the USAGE
    /// line cite every option / flag / positional listed in the schema.
    ///
    /// Inherits the `Root` generic from the enclosing
    /// ``Command/Help`` struct.
    public struct Visitor: Command.Schema.Visitor {
        public typealias Failure = Never

        /// The configuration carried for USAGE-line and ABSTRACT
        /// emission.
        @usableFromInline
        internal let configuration: Command.Configuration

        /// Optional seed instance from which auto-derived defaults are
        /// extracted at visit-time. When non-`nil`, each visit method
        /// reads the bound field via the declaration's `keyPath` and
        /// fills in `Argument.Help.defaults` per the per-binding
        /// rules documented in ``Command/HelpDefault``. When `nil`, no
        /// defaults are auto-derived (the v1.0.15 behavior preserved for
        /// the no-initial overload of ``Command/Help/serialize(_:into:)``).
        @usableFromInline
        internal let initial: Root?

        /// Accumulated rows in declaration order.
        @usableFromInline
        internal var rows: [Command.HelpRow] = []

        /// Creates a visitor capturing `configuration` for the eventual
        /// `render()` call. No `initial` value — auto-derived defaults
        /// are skipped.
        @inlinable
        public init(configuration: Command.Configuration) {
            self.configuration = configuration
            self.initial = nil
        }

        /// Creates a visitor capturing `configuration` and `initial`
        /// for the eventual `render()` call. When `initial` is non-`nil`,
        /// each visit method auto-derives a default-value description
        /// from `initial[keyPath: keyPath]` for any declaration that
        /// did not specify one explicitly.
        @inlinable
        public init(configuration: Command.Configuration, initial: Root) {
            self.configuration = configuration
            self.initial = initial
        }

        public mutating func visit<V: Sendable & Equatable>(
            positional: Command.Positional<Root, V>
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

        public mutating func visit<V: Sendable & Equatable>(
            positionalMany: Command.Positional<Root, V>.Many
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

        public mutating func visit<V: Sendable & Equatable>(
            option: Command.Option<Root, V>
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

        public mutating func visit<V: Sendable & Equatable>(
            optionMany: Command.Option<Root, V>.Many
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

        public mutating func visit(flag: Command.Flag<Root>) throws(Never) {
            // Plain Bool flags do NOT auto-derive a default — the
            // present/absent semantics is what `Flag` models, and
            // rendering `(default: false)` on every flag would be noisy.
            // `HelpDefault.render` already suppresses `Bool` values; we
            // omit the inject call entirely for symmetry.
            rows.append(
                .flag(
                    name: flag.declaration.name,
                    help: flag.declaration.help,
                    visibility: flag.declaration.visibility
                )
            )
        }

        public mutating func visit(
            flagCount: Command.Flag<Root>.Count
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

        public mutating func visit(
            flagInverted: Command.Flag<Root>.Inverted
        ) throws(Never) {
            // `Flag.Inverted` is special: the default-line shape is
            // `(default: --no-feature)` / `(default: --feature)` keyed
            // on the bound `Bool`'s initial value. The shared
            // `HelpDefault.inject` path suppresses `Bool` values, so we
            // derive the rendered side here directly.
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

        public mutating func visit<E: Argument.Flag.Enumerable>(
            flagEnumerable: Command.Flag<Root>.Enumerable<E>
        ) throws(Never) {
            // `Flag.Enumerable` is keyed on `initial[keyPath:]`'s case;
            // the default-line shape is the case's flag name.
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

        public mutating func visit(
            subcommandGroup group: Command.Subcommand.Group<Root>
        ) throws(Never) {
            for binding in group.bindings {
                rows.append(
                    .subcommand(
                        name: binding.name,
                        help: binding.help,
                        visibility: binding.visibility
                    )
                )
            }
        }

        public mutating func visit<G: Sendable & Equatable>(
            optionGroup: Command.OptionGroup<Root, G>
        ) throws(Never) {
            // Inline the group's sub-schema rows into this visitor's row
            // list. A fragment-visitor walks the sub-schema and accumulates
            // `Command.HelpRow` entries in declaration order, which we
            // splice into this visitor's `rows`. The shared Row type
            // (non-generic over Root) means no per-Root re-wrapping is
            // needed.
            //
            // When the group is `.hidden`, the rows are dropped entirely
            // (the parent's USAGE / OPTIONS sections show no trace of the
            // group). When `.visible`, per-sub-node visibility on the
            // fragment's own schema still applies — the parent's
            // visibility is an AND-mask, not an override.
            if optionGroup.visibility == .hidden {
                return
            }
            // Propagate the parent's `initial[keyPath: outerKeyPath]: G`
            // into the fragment collector so OptionGroup sub-fields also
            // pick up auto-derived defaults from their `initial` slice.
            let innerInitial: G? = initial.map { $0[keyPath: optionGroup.keyPath] }
            var fragment = Command.HelpOptionGroupRowCollector<G>(initial: innerInitial)
            optionGroup.schema.accept(&fragment)
            rows.append(contentsOf: fragment.rows)
        }

        /// Renders the accumulated rows into the canonical help-text
        /// format.
        public func render() -> String {
            var output = ""
            output += renderUsage() + "\n"

            if !configuration.abstract.isEmpty {
                output += "\nOVERVIEW: " + configuration.abstract + "\n"
            }

            // Aliases section — mirrors swift-argument-parser's
            // "Aliases:" line which appears after OVERVIEW. Rendered only
            // when the configuration declares one or more aliases.
            if !configuration.aliases.isEmpty {
                output += "\nALIASES: " + configuration.aliases.joined(separator: ", ") + "\n"
            }

            // Discussion section — multi-paragraph extended description.
            // Apple's swift-argument-parser emits this between OVERVIEW
            // and ARGUMENTS; matches that placement.
            if !configuration.discussion.isEmpty {
                output += "\nDISCUSSION:\n"
                for line in configuration.discussion.split(
                    separator: "\n",
                    omittingEmptySubsequences: false
                ) {
                    output += "  " + line + "\n"
                }
            }

            let visibleRows = rows.filter { row in
                switch row {
                case let .positional(_, _, _, visibility),
                     let .positionalMany(_, _, _, visibility),
                     let .option(_, _, _, visibility),
                     let .optionMany(_, _, _, visibility),
                     let .flag(_, _, visibility),
                     let .flagCount(_, _, visibility),
                     let .flagInverted(_, _, _, visibility),
                     let .flagEnumerable(_, _, visibility),
                     let .subcommand(_, _, visibility):
                    return visibility == .visible
                }
            }

            let positionalRows: [Command.HelpRow] = visibleRows.compactMap { row in
                switch row {
                case .positional, .positionalMany:
                    return row
                default:
                    return nil
                }
            }

            if !positionalRows.isEmpty {
                output += "\nARGUMENTS:\n"
                for row in positionalRows {
                    switch row {
                    case let .positional(_, placeholder, help, _):
                        let left = "<\(placeholder)>"
                        var right = help.abstract
                        if let def = help.defaults, !def.isEmpty {
                            right += " (default: \(def))"
                        }
                        output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"
                    case let .positionalMany(_, placeholder, help, _):
                        let left = "<\(placeholder)>..."
                        var right = help.abstract
                        if let def = help.defaults, !def.isEmpty {
                            right += " (default: \(def))"
                        }
                        output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"
                    default:
                        continue
                    }
                }
            }

            // OPTIONS section emitted unconditionally — at minimum --help
            // appears.
            output += "\nOPTIONS:\n"
            for row in visibleRows {
                switch row {
                case .positional, .positionalMany, .subcommand:
                    continue

                case let .option(name, placeholder, help, _):
                    let left = formatOptionName(name) + " <\(placeholder)>"
                    var right = help.abstract
                    if let def = help.defaults, !def.isEmpty {
                        right += " (default: \(def))"
                    }
                    output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"

                case let .optionMany(name, placeholder, help, _):
                    let left = formatOptionName(name) + " <\(placeholder)>..."
                    var right = help.abstract
                    if let def = help.defaults, !def.isEmpty {
                        right += " (default: \(def))"
                    }
                    output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"

                case let .flag(name, help, _):
                    let left = formatOptionName(name)
                    var right = help.abstract
                    if let def = help.defaults, !def.isEmpty {
                        right += " (default: \(def))"
                    }
                    output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"

                case let .flagCount(name, help, _):
                    let left = formatOptionName(name) + "..."
                    var right = help.abstract
                    if let def = help.defaults, !def.isEmpty {
                        right += " (default: \(def))"
                    }
                    output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"

                case let .flagInverted(trueName, falseName, help, _):
                    let left = "--\(trueName)/--\(falseName)"
                    var right = help.abstract
                    if let def = help.defaults, !def.isEmpty {
                        right += " (default: \(def))"
                    }
                    output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"

                case let .flagEnumerable(cases, groupHelp, _):
                    if !groupHelp.abstract.isEmpty || groupHelp.defaults != nil {
                        // Group header row first (carrying any
                        // auto-derived default), then per-case rows
                        // indented under it.
                        var right = groupHelp.abstract
                        if let def = groupHelp.defaults, !def.isEmpty {
                            right += " (default: \(def))"
                        }
                        output += "  " + pad("", to: Self.padWidth) + "  " + right + "\n"
                    }
                    for caseEntry in cases {
                        let left = "--" + caseEntry.name
                        output += "  " + pad(left, to: Self.padWidth) + "  " + caseEntry.help.abstract + "\n"
                    }
                }
            }
            output += "  " + pad("-h, --help", to: Self.padWidth) + "  Show help information.\n"

            // SUBCOMMANDS section: emitted when the schema declares any
            // visible subcommand binding.
            let subcommandRows: [Command.HelpRow] = visibleRows.compactMap { row in
                if case .subcommand = row { return row }
                return nil
            }
            if !subcommandRows.isEmpty {
                output += "\nSUBCOMMANDS:\n"
                for row in subcommandRows {
                    guard case let .subcommand(name, help, _) = row else { continue }
                    output += "  " + pad(name, to: Self.padWidth) + "  " + help.abstract + "\n"
                }
                output += "\n  See '\(configuration.name) help <subcommand>' for detailed help.\n"
            }
            return output
        }

        // MARK: - Helpers

        @usableFromInline
        internal static var padWidth: Int { 24 }

        private func renderUsage() -> String {
            var parts: [String] = ["USAGE:", configuration.name]
            for row in rows {
                switch row {
                case .positional, .positionalMany, .subcommand:
                    continue

                case let .option(name, placeholder, _, visibility):
                    guard visibility == .visible else { continue }
                    parts.append("[\(formatOptionName(name)) <\(placeholder)>]")

                case let .optionMany(name, placeholder, _, visibility):
                    guard visibility == .visible else { continue }
                    parts.append("[\(formatOptionName(name)) <\(placeholder)>]...")

                case let .flag(name, _, visibility):
                    guard visibility == .visible else { continue }
                    parts.append("[\(formatOptionName(name))]")

                case let .flagCount(name, _, visibility):
                    guard visibility == .visible else { continue }
                    parts.append("[\(formatOptionName(name))...]")

                case let .flagInverted(trueName, falseName, _, visibility):
                    guard visibility == .visible else { continue }
                    parts.append("[--\(trueName)|--\(falseName)]")

                case let .flagEnumerable(cases, _, visibility):
                    guard visibility == .visible, !cases.isEmpty else { continue }
                    let caseList = cases.map { "--" + $0.name }.joined(separator: "|")
                    parts.append("[\(caseList)]")
                }
            }
            // If the schema declares any subcommand, render the
            // `<subcommand>` placeholder before positionals (positionals
            // are exclusive of subcommand groups in v1 per the
            // dispatch model documented at
            // ``Command/Schema/ParseVisitor/finalize()``).
            let hasSubcommands = rows.contains { row in
                if case .subcommand = row { return true }
                return false
            }
            if hasSubcommands {
                parts.append("<subcommand>")
            }
            for row in rows {
                switch row {
                case let .positional(_, placeholder, _, visibility):
                    guard visibility == .visible else { continue }
                    parts.append("<\(placeholder)>")
                case let .positionalMany(_, placeholder, _, visibility):
                    guard visibility == .visible else { continue }
                    parts.append("<\(placeholder)>...")
                default:
                    continue
                }
            }
            return parts.joined(separator: " ")
        }

        private func formatOptionName(_ name: Argument.Name) -> String {
            switch name {
            case let .short(short):
                return "-\(short.character)"

            case let .long(long):
                return "--\(long.string)"

            case let .both(short, long):
                return "-\(short.character), --\(long.string)"
            }
        }

        private func pad(_ string: String, to width: Int) -> String {
            if string.count >= width { return string }
            return string + String(repeating: " ", count: width - string.count)
        }
    }
}
