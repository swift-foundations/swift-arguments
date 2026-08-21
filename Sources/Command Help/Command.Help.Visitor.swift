extension Command.Help {

    public struct Visitor: Command.Schema.Visitor {

        public typealias Failure = Never

        @usableFromInline
        internal let configuration: Command.Configuration

        @usableFromInline
        internal let initial: Root?

        @usableFromInline
        internal var rows: [Command.HelpRow] = []

        @inlinable
        public init(configuration: Command.Configuration) {
            self.configuration = configuration
            self.initial = nil
        }

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

            if optionGroup.visibility == .hidden {
                return
            }

            let innerInitial: G? = initial.map { $0[keyPath: optionGroup.keyPath] }
            var fragment = Command.HelpOptionGroupRowCollector<G>(initial: innerInitial)
            optionGroup.schema.accept(&fragment)
            rows.append(contentsOf: fragment.rows)
        }

        public func render() -> String {
            var output = ""
            output += renderUsage() + "\n"

            if !configuration.abstract.isEmpty {
                output += "\nOVERVIEW: " + configuration.abstract + "\n"
            }

            if !configuration.aliases.isEmpty {
                output += "\nALIASES: " + configuration.aliases.joined(separator: ", ") + "\n"
            }

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
                case .positional(_, _, _, let visibility),
                    .positionalMany(_, _, _, let visibility),
                    .option(_, _, _, let visibility),
                    .optionMany(_, _, _, let visibility),
                    .flag(_, _, let visibility),
                    .flagCount(_, _, let visibility),
                    .flagInverted(_, _, _, let visibility),
                    .flagEnumerable(_, _, let visibility),
                    .subcommand(_, _, let visibility):
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
                    case .positional(_, let placeholder, let help, _):
                        let left = "<\(placeholder)>"
                        var right = help.abstract
                        if let def = help.defaults, !def.isEmpty {
                            right += " (default: \(def))"
                        }
                        output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"

                    case .positionalMany(_, let placeholder, let help, _):
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

            output += "\nOPTIONS:\n"
            for row in visibleRows {
                switch row {
                case .positional, .positionalMany, .subcommand:
                    continue

                case .option(let name, let placeholder, let help, _):
                    let left = formatOptionName(name) + " <\(placeholder)>"
                    var right = help.abstract
                    if let def = help.defaults, !def.isEmpty {
                        right += " (default: \(def))"
                    }
                    output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"

                case .optionMany(let name, let placeholder, let help, _):
                    let left = formatOptionName(name) + " <\(placeholder)>..."
                    var right = help.abstract
                    if let def = help.defaults, !def.isEmpty {
                        right += " (default: \(def))"
                    }
                    output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"

                case .flag(let name, let help, _):
                    let left = formatOptionName(name)
                    var right = help.abstract
                    if let def = help.defaults, !def.isEmpty {
                        right += " (default: \(def))"
                    }
                    output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"

                case .flagCount(let name, let help, _):
                    let left = formatOptionName(name) + "..."
                    var right = help.abstract
                    if let def = help.defaults, !def.isEmpty {
                        right += " (default: \(def))"
                    }
                    output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"

                case .flagInverted(let trueName, let falseName, let help, _):
                    let left = "--\(trueName)/--\(falseName)"
                    var right = help.abstract
                    if let def = help.defaults, !def.isEmpty {
                        right += " (default: \(def))"
                    }
                    output += "  " + pad(left, to: Self.padWidth) + "  " + right + "\n"

                case .flagEnumerable(let cases, let groupHelp, _):
                    if !groupHelp.abstract.isEmpty || groupHelp.defaults != nil {

                        var right = groupHelp.abstract
                        if let def = groupHelp.defaults, !def.isEmpty {
                            right += " (default: \(def))"
                        }
                        output += "  " + pad("", to: Self.padWidth) + "  " + right + "\n"
                    }
                    for caseEntry in cases {
                        let left = "--" + caseEntry.name
                        output +=
                            "  " + pad(left, to: Self.padWidth) + "  " + caseEntry.help.abstract
                            + "\n"
                    }
                }
            }
            output += "  " + pad("-h, --help", to: Self.padWidth) + "  Show help information.\n"

            let subcommandRows: [Command.HelpRow] = visibleRows.compactMap { row in
                if case .subcommand = row { return row }
                return nil
            }
            if !subcommandRows.isEmpty {
                output += "\nSUBCOMMANDS:\n"
                for row in subcommandRows {
                    guard case .subcommand(let name, let help, _) = row else { continue }
                    output += "  " + pad(name, to: Self.padWidth) + "  " + help.abstract + "\n"
                }
                output += "\n  See '\(configuration.name) help <subcommand>' for detailed help.\n"
            }
            return output
        }

        @usableFromInline
        internal static var padWidth: Int { 24 }

        private func renderUsage() -> String {
            var parts: [String] = ["USAGE:", configuration.name]
            for row in rows {
                switch row {
                case .positional, .positionalMany, .subcommand:
                    continue

                case .option(let name, let placeholder, _, let visibility):
                    guard visibility == .visible else { continue }
                    parts.append("[\(formatOptionName(name)) <\(placeholder)>]")

                case .optionMany(let name, let placeholder, _, let visibility):
                    guard visibility == .visible else { continue }
                    parts.append("[\(formatOptionName(name)) <\(placeholder)>]...")

                case .flag(let name, _, let visibility):
                    guard visibility == .visible else { continue }
                    parts.append("[\(formatOptionName(name))]")

                case .flagCount(let name, _, let visibility):
                    guard visibility == .visible else { continue }
                    parts.append("[\(formatOptionName(name))...]")

                case .flagInverted(let trueName, let falseName, _, let visibility):
                    guard visibility == .visible else { continue }
                    parts.append("[--\(trueName)|--\(falseName)]")

                case .flagEnumerable(let cases, _, let visibility):
                    guard visibility == .visible, !cases.isEmpty else { continue }
                    let caseList = cases.map { "--" + $0.name }.joined(separator: "|")
                    parts.append("[\(caseList)]")
                }
            }

            let hasSubcommands = rows.contains { row in
                if case .subcommand = row { return true }
                return false
            }
            if hasSubcommands {
                parts.append("<subcommand>")
            }
            for row in rows {
                switch row {
                case .positional(_, let placeholder, _, let visibility):
                    guard visibility == .visible else { continue }
                    parts.append("<\(placeholder)>")

                case .positionalMany(_, let placeholder, _, let visibility):
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
            case .short(let short):
                return "-\(short.character)"

            case .long(let long):
                return "--\(long.string)"

            case .both(let short, let long):
                return "-\(short.character), --\(long.string)"
            }
        }

        private func pad(_ string: String, to width: Int) -> String {
            if string.count >= width { return string }
            return string + String(repeating: " ", count: width - string.count)
        }
    }
}
