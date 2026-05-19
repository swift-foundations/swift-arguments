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
    /// The Schema-internal help-text visitor used for sub-command
    /// help rendering.
    ///
    /// Mirrors ``Command/Help/Visitor`` in output shape, but lives in
    /// the Schema target so ``Command/Subcommand/Binding`` conformance
    /// can render without depending on the `Command Help` target.
    ///
    /// Per the v1 layering note, this is intentional duplication. A v2
    /// cleanup may consolidate via a single Schema-level rendering
    /// primitive once the L3 help surface stabilizes.
    public struct Visitor<Root: Command.`Protocol`>: Command.Schema.Visitor {
        public typealias Failure = Never

        /// The configuration carried for USAGE-line and OVERVIEW emission.
        @usableFromInline
        internal let configuration: Command.Configuration

        /// Optional seed instance from which auto-derived defaults are
        /// extracted at visit-time. Mirrors ``Command/Help/Visitor``'s
        /// `initial` slot — same semantics, same per-binding rules. See
        /// ``Command/Subcommand/HelpDefault`` for the rendering helpers.
        @usableFromInline
        internal let initial: Root?

        /// Accumulated rows in declaration order.
        ///
        /// Carried in the shared ``Command/Subcommand/Help/Row`` shape so
        /// option-group sub-schemas (rooted on a fragment type `G`) can
        /// splice their rows directly without per-Root re-wrapping.
        @usableFromInline
        internal var rows: [Command.Subcommand.Help.Row] = []

        /// Creates a visitor capturing `configuration` for the eventual
        /// ``render()`` call. No `initial` — auto-derived defaults
        /// are skipped.
        @inlinable
        public init(configuration: Command.Configuration) {
            self.configuration = configuration
            self.initial = nil
        }

        /// Creates a visitor capturing `configuration` and `initial`
        /// for the eventual ``render()`` call. When `initial` is
        /// non-`nil`, each visit method auto-derives a default-value
        /// description from `initial[keyPath: keyPath]` for any
        /// declaration that did not specify one explicitly.
        @inlinable
        public init(configuration: Command.Configuration, initial: Root) {
            self.configuration = configuration
            self.initial = initial
        }

        public mutating func visit<V: Sendable & Equatable>(
            positional: Command.Positional<Root, V>
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

        public mutating func visit<V: Sendable & Equatable>(
            positionalMany: Command.Positional<Root, V>.Many
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

        public mutating func visit<V: Sendable & Equatable>(
            option: Command.Option<Root, V>
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

        public mutating func visit<V: Sendable & Equatable>(
            optionMany: Command.Option<Root, V>.Many
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

        public mutating func visit(flag: Command.Flag<Root>) throws(Never) {
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

        public mutating func visit(
            flagInverted: Command.Flag<Root>.Inverted
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

        public mutating func visit<E: Argument.Flag.Enumerable>(
            flagEnumerable: Command.Flag<Root>.Enumerable<E>
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

        public mutating func visit(subcommandGroup: Command.Subcommand.Group<Root>) throws(Never) {
            for binding in subcommandGroup.bindings {
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
            // list. Mirrors ``Command/Help/Visitor``'s implementation —
            // a sibling row collector walks the fragment schema and
            // produces ``Command/Subcommand/Help/Row`` entries which we
            // splice in declaration order.
            if optionGroup.visibility == .hidden {
                return
            }
            let innerInitial: G? = initial.map { $0[keyPath: optionGroup.keyPath] }
            var fragment = Command.Subcommand.Help.OptionGroupRowCollector<G>(initial: innerInitial)
            optionGroup.schema.accept(&fragment)
            rows.append(contentsOf: fragment.rows)
        }

        /// Renders the accumulated rows into the canonical help-text format.
        public func render() -> String {
            var output = ""
            output += renderUsage() + "\n"

            if !configuration.abstract.isEmpty {
                output += "\nOVERVIEW: " + configuration.abstract + "\n"
            }

            // Aliases section — emitted for subcommands whose binding
            // declares alternate names. Mirrors the placement used in
            // ``Command/Help/Visitor`` so the top-level and sub-level
            // help layouts stay symmetric.
            if !configuration.aliases.isEmpty {
                output += "\nALIASES: " + configuration.aliases.joined(separator: ", ") + "\n"
            }

            // Discussion section — multi-paragraph extended description.
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

            let positionalRows: [Command.Subcommand.Help.Row] = visibleRows.compactMap { row in
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
                    case let .positional(_, valueName, help, _):
                        let left = "<\(valueName)>"
                        var right = help.abstract
                        if let def = help.defaultDescription, !def.isEmpty {
                            right += " (default: \(def))"
                        }
                        output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"
                    case let .positionalMany(_, valueName, help, _):
                        let left = "<\(valueName)>..."
                        var right = help.abstract
                        if let def = help.defaultDescription, !def.isEmpty {
                            right += " (default: \(def))"
                        }
                        output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"
                    default:
                        continue
                    }
                }
            }

            // OPTIONS section emitted unconditionally — at minimum --help appears.
            output += "\nOPTIONS:\n"
            for row in visibleRows {
                switch row {
                case .positional, .positionalMany, .subcommand:
                    continue

                case let .option(name, valueName, help, _):
                    let left = formatOptionName(name) + " <\(valueName)>"
                    var right = help.abstract
                    if let def = help.defaultDescription, !def.isEmpty {
                        right += " (default: \(def))"
                    }
                    output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"

                case let .optionMany(name, valueName, help, _):
                    let left = formatOptionName(name) + " <\(valueName)>..."
                    var right = help.abstract
                    if let def = help.defaultDescription, !def.isEmpty {
                        right += " (default: \(def))"
                    }
                    output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"

                case let .flag(name, help, _):
                    let left = formatOptionName(name)
                    var right = help.abstract
                    if let def = help.defaultDescription, !def.isEmpty {
                        right += " (default: \(def))"
                    }
                    output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"

                case let .flagCount(name, help, _):
                    let left = formatOptionName(name) + "..."
                    var right = help.abstract
                    if let def = help.defaultDescription, !def.isEmpty {
                        right += " (default: \(def))"
                    }
                    output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"

                case let .flagInverted(trueName, falseName, help, _):
                    let left = "--\(trueName)/--\(falseName)"
                    var right = help.abstract
                    if let def = help.defaultDescription, !def.isEmpty {
                        right += " (default: \(def))"
                    }
                    output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"

                case let .flagEnumerable(cases, groupHelp, _):
                    if !groupHelp.abstract.isEmpty || groupHelp.defaultDescription != nil {
                        var right = groupHelp.abstract
                        if let def = groupHelp.defaultDescription, !def.isEmpty {
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

            // SUBCOMMANDS section.
            let subcommandRows: [Command.Subcommand.Help.Row] = visibleRows.compactMap { row in
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

                case let .option(name, valueName, _, visibility):
                    guard visibility == .visible else { continue }
                    parts.append("[\(formatOptionName(name)) <\(valueName)>]")

                case let .optionMany(name, valueName, _, visibility):
                    guard visibility == .visible else { continue }
                    parts.append("[\(formatOptionName(name)) <\(valueName)>]...")

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
            // If this command has any subcommand declarations, render
            // `<subcommand>` placeholder.
            let hasSubcommands = rows.contains { row in
                if case .subcommand = row { return true }
                return false
            }
            if hasSubcommands {
                parts.append("<subcommand>")
            }
            for row in rows {
                switch row {
                case let .positional(_, valueName, _, visibility):
                    guard visibility == .visible else { continue }
                    parts.append("<\(valueName)>")
                case let .positionalMany(_, valueName, _, visibility):
                    guard visibility == .visible else { continue }
                    parts.append("<\(valueName)>...")
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
