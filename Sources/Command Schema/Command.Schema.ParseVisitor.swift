internal import Affine_Carrier_Primitives
internal import Affine_Tagged_Primitives
internal import Index_Primitives
internal import Ordinal_Primitive
internal import Ordinal_Tagged_Primitives
public import Tagged_Primitives
internal import Text_Primitives

extension Command.Schema {

    public struct ParseVisitor<Root: Sendable>: Sendable {

        @usableFromInline
        internal let tokens: [Argument.Token]

        public var root: Root

        @usableFromInline
        internal var positionals: [PositionalEntry] = []

        @usableFromInline
        internal var positionalMany: PositionalManyEntry?

        @usableFromInline
        internal var options: [OptionEntry] = []

        @usableFromInline
        internal var optionManies: [OptionManyEntry] = []

        @usableFromInline
        internal var filledOptionIndices: Set<Int> = []

        @usableFromInline
        internal var flags: [FlagEntry] = []

        @usableFromInline
        internal var flagCounts: [FlagCountEntry] = []

        @usableFromInline
        internal var flagInverteds: [FlagInvertedEntry] = []

        @usableFromInline
        internal var flagEnumerables: [FlagEnumerableEntry] = []

        @usableFromInline
        internal var subcommandGroup: SubcommandGroupEntry?

        @usableFromInline
        internal let argv: [String]

        @usableFromInline
        internal let rootName: String

        @usableFromInline
        internal let rootVersion: String

        @inlinable
        public init(tokens: [Argument.Token], root: Root) {
            self.tokens = tokens
            self.argv = []
            self.rootName = ""
            self.rootVersion = ""
            self.root = root
        }

        @inlinable
        public init(
            tokens: [Argument.Token],
            argv: [String],
            rootName: String,
            rootVersion: String = "",
            root: Root
        ) {
            self.tokens = tokens
            self.argv = argv
            self.rootName = rootName
            self.rootVersion = rootVersion
            self.root = root
        }
    }
}

extension Command.Schema.ParseVisitor {

    @usableFromInline
    internal struct PositionalEntry: Sendable {

        @usableFromInline let name: String

        @usableFromInline let apply: @Sendable (String, inout Root) -> Bool
    }

    @usableFromInline
    internal struct PositionalManyEntry: Sendable {

        @usableFromInline let name: String

        @usableFromInline let arity: Argument.Arity

        @usableFromInline let append: @Sendable (String, inout Root) -> Bool

        @usableFromInline let count: @Sendable (Root) -> Int
    }

    @usableFromInline
    internal struct OptionEntry: Sendable {

        @usableFromInline let name: Argument.Name

        @usableFromInline let apply: @Sendable (String, inout Root) -> Bool

        @usableFromInline let environment: Argument.Environment.Variable.Name?
    }

    @usableFromInline
    internal struct OptionManyEntry: Sendable {

        @usableFromInline let name: Argument.Name

        @usableFromInline let arity: Argument.Arity

        @usableFromInline let append: @Sendable (String, inout Root) -> Bool

        @usableFromInline let count: @Sendable (Root) -> Int
    }

    @usableFromInline
    internal struct FlagEntry: Sendable {

        @usableFromInline let name: Argument.Name

        @usableFromInline let apply: @Sendable (inout Root) -> Void
    }

    @usableFromInline
    internal struct FlagCountEntry: Sendable {

        @usableFromInline let name: Argument.Name

        @usableFromInline let increment: @Sendable (inout Root) -> Void
    }

    @usableFromInline
    internal struct FlagInvertedEntry: Sendable {

        @usableFromInline let trueName: String

        @usableFromInline let falseName: String

        @usableFromInline let apply: @Sendable (Bool, inout Root) -> Void
    }

    @usableFromInline
    internal struct FlagEnumerableEntry: Sendable {

        @usableFromInline let casesByLongName: [String: @Sendable (inout Root) -> Void]
    }

    @usableFromInline
    internal struct SubcommandGroupEntry: Sendable {

        @usableFromInline let bindings: [any Command.Subcommand.Binding<Root>]
    }

}

extension Command.Schema.ParseVisitor: Command.Schema.Visitor {

    public typealias Failure = Command.Error

    public mutating func visit<V: Sendable & Equatable>(
        positional: Command.Positional<Root, V>
    ) throws(Command.Error) {
        let keyPath = positional.keyPath
        let parse = positional.parse
        positionals.append(
            PositionalEntry(
                name: positional.declaration.name,
                apply: { value, root in
                    guard let parsed = parse(value) else { return false }
                    root[keyPath: keyPath] = parsed
                    return true
                }
            )
        )
    }

    public mutating func visit<V: Sendable & Equatable>(
        positionalMany: Command.Positional<Root, V>.Many
    ) throws(Command.Error) {
        guard self.positionalMany == nil else {
            throw .validationFailed(
                reason: "Schema declares more than one Command.Positional.Many; "
                    + "at most one array-positional is permitted because "
                    + "greedy consumption is otherwise ambiguous."
            )
        }
        let keyPath = positionalMany.keyPath
        let parse = positionalMany.parse
        self.positionalMany = PositionalManyEntry(
            name: positionalMany.declaration.name,
            arity: positionalMany.declaration.arity,
            append: { value, root in
                guard let parsed = parse(value) else { return false }
                root[keyPath: keyPath].append(parsed)
                return true
            },
            count: { root in
                root[keyPath: keyPath].count
            }
        )
    }

    public mutating func visit<V: Sendable & Equatable>(
        option: Command.Option<Root, V>
    ) throws(Command.Error) {
        let keyPath = option.keyPath
        let parse = option.parse
        options.append(
            OptionEntry(
                name: option.declaration.name,
                apply: { value, root in
                    guard let parsed = parse(value) else { return false }
                    root[keyPath: keyPath] = parsed
                    return true
                },
                environment: option.declaration.environment
            )
        )
    }

    public mutating func visit<V: Sendable & Equatable>(
        optionMany: Command.Option<Root, V>.Many
    ) throws(Command.Error) {
        let keyPath = optionMany.keyPath
        let parse = optionMany.parse
        optionManies.append(
            OptionManyEntry(
                name: optionMany.declaration.name,
                arity: optionMany.declaration.arity,
                append: { value, root in
                    guard let parsed = parse(value) else { return false }
                    root[keyPath: keyPath].append(parsed)
                    return true
                },
                count: { root in
                    root[keyPath: keyPath].count
                }
            )
        )
    }

    public mutating func visit(flag: Command.Flag<Root>) throws(Command.Error) {
        let keyPath = flag.keyPath
        flags.append(
            FlagEntry(
                name: flag.declaration.name,
                apply: { root in
                    root[keyPath: keyPath] = true
                }
            )
        )
    }

    public mutating func visit(
        flagCount: Command.Flag<Root>.Count
    ) throws(Command.Error) {
        let keyPath = flagCount.keyPath
        flagCounts.append(
            FlagCountEntry(
                name: flagCount.declaration.name,
                increment: { root in
                    root[keyPath: keyPath] += 1
                }
            )
        )
    }

    public mutating func visit(
        flagInverted: Command.Flag<Root>.Inverted
    ) throws(Command.Error) {
        let keyPath = flagInverted.keyPath
        flagInverteds.append(
            FlagInvertedEntry(
                trueName: flagInverted.trueName,
                falseName: flagInverted.falseName,
                apply: { value, root in
                    root[keyPath: keyPath] = value
                }
            )
        )
    }

    public mutating func visit<E: Argument.Flag.Enumerable>(
        flagEnumerable: Command.Flag<Root>.Enumerable<E>
    ) throws(Command.Error) {
        let keyPath = flagEnumerable.keyPath
        var casesByLongName: [String: @Sendable (inout Root) -> Void] = [:]
        for value in E.allCases {
            let name = E.name(for: value).string
            let captured = value
            casesByLongName[name] = { root in
                root[keyPath: keyPath] = captured
            }
        }
        flagEnumerables.append(
            FlagEnumerableEntry(casesByLongName: casesByLongName)
        )
    }

    public mutating func visit(
        subcommandGroup group: Command.Subcommand.Group<Root>
    ) throws(Command.Error) {

        self.subcommandGroup = SubcommandGroupEntry(bindings: group.bindings)
    }

    public mutating func visit<G: Sendable & Equatable>(
        optionGroup: Command.OptionGroup<Root, G>
    ) throws(Command.Error) {

        var forwarder = Command.Schema.OptionGroupForwarder<Root, G>(
            outerKeyPath: optionGroup.keyPath
        )
        try optionGroup.schema.accept(&forwarder)
        positionals.append(contentsOf: forwarder.positionals)
        if let many = forwarder.positionalMany {
            guard self.positionalMany == nil else {
                throw .validationFailed(
                    reason: "Schema declares more than one Command.Positional.Many "
                        + "(including via OptionGroup forwarding); at most one "
                        + "array-positional is permitted."
                )
            }
            self.positionalMany = many
        }
        options.append(contentsOf: forwarder.options)
        optionManies.append(contentsOf: forwarder.optionManies)
        flags.append(contentsOf: forwarder.flags)
        flagCounts.append(contentsOf: forwarder.flagCounts)
        flagInverteds.append(contentsOf: forwarder.flagInverteds)
        flagEnumerables.append(contentsOf: forwarder.flagEnumerables)
    }
}

extension Command.Schema.ParseVisitor {

    public mutating func finalize() throws(Command.Error) {

        if let group = subcommandGroup {
            guard
                positionals.isEmpty,
                positionalMany == nil,
                options.isEmpty,
                optionManies.isEmpty,
                flags.isEmpty,
                flagCounts.isEmpty,
                flagInverteds.isEmpty,
                flagEnumerables.isEmpty
            else {
                throw .validationFailed(
                    reason: "Schema declares a Command.Subcommand.Group together with "
                        + "root-level KeyPath-bound positional/option/flag declarations. "
                        + "Root-level values would be silently discarded when the matched "
                        + "subcommand's parse(subArgv:) replaces the root instance wholesale — "
                        + "Command.Subcommand.Binding.parse(subArgv:) has no way to thread the "
                        + "pre-dispatch root forward. Remove the root-level declarations, or "
                        + "move them into each subcommand's own schema, until a future Binding "
                        + "API revision can merge root-level state across dispatch."
                )
            }
            try dispatchSubcommand(group: group)
            return
        }

        var positionalCursor: Int = 0
        var index: Int = 0
        var afterEndOfOptions = false

        while index < tokens.count {
            let token = tokens[index]

            if afterEndOfOptions {

                switch token.kind {
                case .positional(let string):
                    try applyPositional(string: string, cursor: &positionalCursor, token: token)

                case .endOfOptions:

                    break

                default:

                    if case .value(let string) = token.kind {
                        try applyPositional(
                            string: string,
                            cursor: &positionalCursor,
                            token: token
                        )
                    }
                }
                index += 1
                continue
            }

            switch token.kind {
            case .endOfOptions:
                afterEndOfOptions = true
                index += 1

            case .long(let name):
                try applyLong(name: name, tokenIndex: &index, token: token)

            case .shortCluster(let cluster):

                if let firstChar = cluster.first,
                    firstChar.isASCII, firstChar.isNumber,
                    !hasShortBinding(for: firstChar),
                    (positionalCursor < positionals.count) || (positionalMany != nil)
                {

                    var positionalString = "-" + cluster
                    var advance = 1
                    if index + 1 < tokens.count,
                        case .value(let continuation) = tokens[index + 1].kind,
                        tokens[index + 1].range == token.range
                    {
                        positionalString += continuation
                        advance = 2
                    }
                    try applyPositional(
                        string: positionalString,
                        cursor: &positionalCursor,
                        token: token
                    )
                    index += advance
                    continue
                }
                try applyShortCluster(cluster: cluster, tokenIndex: &index, token: token)

            case .positional(let string):
                try applyPositional(string: string, cursor: &positionalCursor, token: token)
                index += 1

            case .value:

                if case .value(let string) = token.kind {
                    try applyPositional(string: string, cursor: &positionalCursor, token: token)
                }
                index += 1

            case .separator:

                index += 1
            }
        }

        try applyEnvironmentVariableFallbacks()

        if positionalCursor < positionals.count {
            let missing = positionals[positionalCursor]
            throw .missingPositional(
                name: missing.name,
                position: .init(argvIndex: .zero, byteOffset: .zero)
            )
        }

        try validatePositionalManyArity()

        try validateOptionManyArities()
    }

    @usableFromInline
    internal mutating func applyEnvironmentVariableFallbacks() throws(Command.Error) {
        for (optionIndex, entry) in options.enumerated() {
            guard !filledOptionIndices.contains(optionIndex) else { continue }
            guard let envVar = entry.environment else { continue }
            guard let value = Self.readEnvironmentVariable(envVar.underlying) else { continue }
            guard entry.apply(value, &root) else {
                throw .invalidEnvironmentValue(
                    name: Self.publicName(for: entry.name),
                    environment: envVar,
                    value: value
                )
            }
            filledOptionIndices.insert(optionIndex)
        }
    }

    @usableFromInline
    internal static func publicName(for name: Argument.Name) -> String {
        switch name {
        case .short(let short):
            return "-\(short.character)"

        case .long(let long):
            return "--\(long.string)"

        case .both(let short, let long):
            return "-\(short.character), --\(long.string)"
        }
    }

    @usableFromInline
    internal mutating func applyPositional(
        string: String,
        cursor: inout Int,
        token: Argument.Token
    ) throws(Command.Error) {

        if cursor < positionals.count {
            let entry = positionals[cursor]
            guard entry.apply(string, &root) else {
                throw .invalidValue(
                    name: entry.name,
                    value: string,
                    position: position(from: token)
                )
            }
            cursor += 1
            return
        }

        if let many = positionalMany {
            guard many.append(string, &root) else {
                throw .invalidValue(
                    name: many.name,
                    value: string,
                    position: position(from: token)
                )
            }
            return
        }

        throw .unexpectedPositional(
            value: string,
            position: position(from: token)
        )
    }

    @usableFromInline
    internal mutating func validatePositionalManyArity() throws(Command.Error) {
        guard let many = positionalMany else { return }
        let count = many.count(root)
        try Self.checkArityBounds(
            arity: many.arity,
            count: count,
            name: many.name,
            kind: "positional"
        )
    }

    @usableFromInline
    internal mutating func validateOptionManyArities() throws(Command.Error) {
        for many in optionManies {
            let count = many.count(root)
            try Self.checkArityBounds(
                arity: many.arity,
                count: count,
                name: Self.publicName(for: many.name),
                kind: "option"
            )
        }
    }

    @usableFromInline
    internal static func checkArityBounds(
        arity: Argument.Arity,
        count: Int,
        name: String,
        kind: String
    ) throws(Command.Error) {
        switch arity {
        case .exactly(let target):
            guard count == target else {
                throw .validationFailed(
                    reason:
                        "Expected exactly \(target) value(s) for \(kind) '\(name)', got \(count)."
                )
            }

        case .atMost(let maximum):
            guard count <= maximum else {
                throw .validationFailed(
                    reason:
                        "Expected at most \(maximum) value(s) for \(kind) '\(name)', got \(count)."
                )
            }

        case .atLeast(let minimum):
            guard count >= minimum else {
                throw .validationFailed(
                    reason:
                        "Expected at least \(minimum) value(s) for \(kind) '\(name)', got \(count)."
                )
            }

        case .range(let range):
            guard range.contains(count) else {
                throw .validationFailed(
                    reason: "Expected \(range.lowerBound)…\(range.upperBound) value(s) for \(kind) "
                        + "'\(name)', got \(count)."
                )
            }

        case .count:

            break
        }
    }

    @usableFromInline
    internal mutating func applyLong(
        name: String,
        tokenIndex: inout Int,
        token: Argument.Token
    ) throws(Command.Error) {

        if let optionIndex = options.firstIndex(where: { $0.name.long?.string == name }) {
            let option = options[optionIndex]
            let valueString = try consumeOptionValue(
                optionDisplay: "--\(name)",
                tokenIndex: &tokenIndex,
                token: token
            )
            guard option.apply(valueString, &root) else {
                throw .invalidValue(
                    name: "--\(name)",
                    value: valueString,
                    position: position(from: token)
                )
            }
            filledOptionIndices.insert(optionIndex)
            return
        }

        if let manyIndex = optionManies.firstIndex(where: { $0.name.long?.string == name }) {
            let many = optionManies[manyIndex]
            let valueString = try consumeOptionValue(
                optionDisplay: "--\(name)",
                tokenIndex: &tokenIndex,
                token: token
            )
            guard many.append(valueString, &root) else {
                throw .invalidValue(
                    name: "--\(name)",
                    value: valueString,
                    position: position(from: token)
                )
            }
            return
        }

        if let flagIndex = flags.firstIndex(where: { $0.name.long?.string == name }) {
            flags[flagIndex].apply(&root)
            tokenIndex += 1
            return
        }

        if let countIndex = flagCounts.firstIndex(where: { $0.name.long?.string == name }) {
            flagCounts[countIndex].increment(&root)
            tokenIndex += 1
            return
        }

        if let invertedIndex = flagInverteds.firstIndex(where: { $0.trueName == name }) {
            flagInverteds[invertedIndex].apply(true, &root)
            tokenIndex += 1
            return
        }
        if let invertedIndex = flagInverteds.firstIndex(where: { $0.falseName == name }) {
            flagInverteds[invertedIndex].apply(false, &root)
            tokenIndex += 1
            return
        }

        for entry in flagEnumerables {
            if let apply = entry.casesByLongName[name] {
                apply(&root)
                tokenIndex += 1
                return
            }
        }

        if name == "help" {
            throw .helpRequested
        }

        if name == "version", !rootVersion.isEmpty {
            throw .versionRequested(version: rootVersion)
        }

        let suggestion = Command.Diagnostic.Suggestion.closest(
            to: name,
            among: declaredLongOptionNames()
        )
        throw .unknownLongOption(
            name: "--\(name)",
            position: position(from: token),
            suggestion: suggestion
        )
    }

    @usableFromInline
    internal func consumeOptionValue(
        optionDisplay: String,
        tokenIndex: inout Int,
        token: Argument.Token
    ) throws(Command.Error) -> String {
        let valueIndex = tokenIndex + 1
        guard valueIndex < tokens.count else {
            throw .missingOptionValue(
                name: optionDisplay,
                position: position(from: token)
            )
        }
        let valueToken = tokens[valueIndex]
        switch valueToken.kind {
        case .value(let string):
            tokenIndex = valueIndex + 1
            return string

        case .positional(let string):

            tokenIndex = valueIndex + 1
            return string

        default:
            throw .missingOptionValue(
                name: optionDisplay,
                position: position(from: token)
            )
        }
    }

    @usableFromInline
    internal mutating func applyShortCluster(
        cluster: String,
        tokenIndex: inout Int,
        token: Argument.Token
    ) throws(Command.Error) {

        var effectiveCluster = cluster
        var spliceAdvance = 0
        if cluster.count == 1,
            tokenIndex + 1 < tokens.count,
            case .value(let continuation) = tokens[tokenIndex + 1].kind,
            tokens[tokenIndex + 1].range == token.range
        {
            guard let firstChar = cluster.first else {
                fatalError("unreachable — cluster.count == 1 guarantees a first element")
            }
            let isValueOption =
                options.contains { $0.name.short?.character == firstChar }
                || optionManies.contains { $0.name.short?.character == firstChar }
            if !isValueOption {
                effectiveCluster = cluster + continuation
                spliceAdvance = 1
            }
        }

        if effectiveCluster.count == 1 {
            guard let firstChar = effectiveCluster.first else {
                fatalError("unreachable — effectiveCluster.count == 1 guarantees a first element")
            }

            if let optionIndex = options.firstIndex(
                where: { $0.name.short?.character == firstChar }
            ) {
                let option = options[optionIndex]
                let valueString = try consumeOptionValue(
                    optionDisplay: "-\(firstChar)",
                    tokenIndex: &tokenIndex,
                    token: token
                )
                guard option.apply(valueString, &root) else {
                    throw .invalidValue(
                        name: "-\(firstChar)",
                        value: valueString,
                        position: position(from: token)
                    )
                }
                filledOptionIndices.insert(optionIndex)
                return
            }

            if let manyIndex = optionManies.firstIndex(
                where: { $0.name.short?.character == firstChar }
            ) {
                let many = optionManies[manyIndex]
                let valueString = try consumeOptionValue(
                    optionDisplay: "-\(firstChar)",
                    tokenIndex: &tokenIndex,
                    token: token
                )
                guard many.append(valueString, &root) else {
                    throw .invalidValue(
                        name: "-\(firstChar)",
                        value: valueString,
                        position: position(from: token)
                    )
                }
                return
            }

            if let flagIndex = flags.firstIndex(
                where: { $0.name.short?.character == firstChar }
            ) {
                flags[flagIndex].apply(&root)
                tokenIndex += 1
                return
            }

            if let countIndex = flagCounts.firstIndex(
                where: { $0.name.short?.character == firstChar }
            ) {
                flagCounts[countIndex].increment(&root)
                tokenIndex += 1
                return
            }

            if firstChar == "h" {
                throw .helpRequested
            }

            throw .unknownShortOption(
                name: firstChar,
                position: position(from: token)
            )
        }

        for character in effectiveCluster {
            if let flagIndex = flags.firstIndex(
                where: { $0.name.short?.character == character }
            ) {
                flags[flagIndex].apply(&root)
            } else if let countIndex = flagCounts.firstIndex(
                where: { $0.name.short?.character == character }
            ) {
                flagCounts[countIndex].increment(&root)
            } else {
                throw .unknownShortOption(
                    name: character,
                    position: position(from: token)
                )
            }
        }
        tokenIndex += 1 + spliceAdvance
    }

    @usableFromInline
    internal func position(from token: Argument.Token) -> Argument.Position {
        Argument.Position(
            argvIndex: .zero,
            byteOffset: .init(fromZero: token.range.start)
        )
    }

    @usableFromInline
    internal func hasShortBinding(for character: Character) -> Bool {
        if options.contains(where: { $0.name.short?.character == character }) { return true }
        if optionManies.contains(where: { $0.name.short?.character == character }) { return true }
        if flags.contains(where: { $0.name.short?.character == character }) { return true }
        if flagCounts.contains(where: { $0.name.short?.character == character }) { return true }
        return false
    }

    @usableFromInline
    internal func declaredLongOptionNames() -> [String] {
        var names: [String] = []
        for entry in options { if let long = entry.name.long { names.append(long.string) } }
        for entry in optionManies { if let long = entry.name.long { names.append(long.string) } }
        for entry in flags { if let long = entry.name.long { names.append(long.string) } }
        for entry in flagCounts { if let long = entry.name.long { names.append(long.string) } }
        for entry in flagInverteds {
            names.append(entry.trueName)
            names.append(entry.falseName)
        }
        for entry in flagEnumerables {
            for name in entry.casesByLongName.keys {
                names.append(name)
            }
        }
        names.append("help")
        if !rootVersion.isEmpty { names.append("version") }
        return names
    }

    @usableFromInline
    internal mutating func dispatchSubcommand(
        group: SubcommandGroupEntry
    ) throws(Command.Error) {

        var argvIndex = 0
        while argvIndex < argv.count {
            let element = argv[argvIndex]

            if element == "--help" || element == "-h" {
                throw .helpRequested
            }

            if element == "--version", !rootVersion.isEmpty {
                throw .versionRequested(version: rootVersion)
            }

            if element.hasPrefix("--") {
                let trimmed = String(element.dropFirst(2))
                let (name, inlineValue): (String, String?) = {
                    if let eq = trimmed.firstIndex(of: "=") {
                        return (
                            String(trimmed[..<eq]), String(trimmed[trimmed.index(after: eq)...])
                        )
                    }
                    return (trimmed, nil)
                }()

                if let optionIndex = options.firstIndex(where: { $0.name.long?.string == name }) {
                    let option = options[optionIndex]
                    let valueString = try rootConsumeLongOptionValue(
                        name: "--\(name)",
                        inlineValue: inlineValue,
                        argvIndex: &argvIndex
                    )
                    guard option.apply(valueString, &root) else {
                        throw .invalidValue(
                            name: "--\(name)",
                            value: valueString,
                            position: .init(
                                argvIndex: Index<String>(Ordinal(UInt(argvIndex))),
                                byteOffset: .zero
                            )
                        )
                    }
                    filledOptionIndices.insert(optionIndex)
                    continue
                }

                if let manyIndex = optionManies.firstIndex(where: { $0.name.long?.string == name })
                {
                    let many = optionManies[manyIndex]
                    let valueString = try rootConsumeLongOptionValue(
                        name: "--\(name)",
                        inlineValue: inlineValue,
                        argvIndex: &argvIndex
                    )
                    guard many.append(valueString, &root) else {
                        throw .invalidValue(
                            name: "--\(name)",
                            value: valueString,
                            position: .init(
                                argvIndex: Index<String>(Ordinal(UInt(argvIndex))),
                                byteOffset: .zero
                            )
                        )
                    }
                    continue
                }

                if let flagIndex = flags.firstIndex(where: { $0.name.long?.string == name }) {
                    flags[flagIndex].apply(&root)
                    argvIndex += 1
                    continue
                }

                if let countIndex = flagCounts.firstIndex(where: { $0.name.long?.string == name }) {
                    flagCounts[countIndex].increment(&root)
                    argvIndex += 1
                    continue
                }

                if let invertedIndex = flagInverteds.firstIndex(where: { $0.trueName == name }) {
                    flagInverteds[invertedIndex].apply(true, &root)
                    argvIndex += 1
                    continue
                }
                if let invertedIndex = flagInverteds.firstIndex(where: { $0.falseName == name }) {
                    flagInverteds[invertedIndex].apply(false, &root)
                    argvIndex += 1
                    continue
                }

                var matchedEnumerable = false
                for entry in flagEnumerables {
                    if let apply = entry.casesByLongName[name] {
                        apply(&root)
                        argvIndex += 1
                        matchedEnumerable = true
                        break
                    }
                }
                if matchedEnumerable { continue }

                let suggestion = Command.Diagnostic.Suggestion.closest(
                    to: name,
                    among: declaredLongOptionNames()
                )
                throw .unknownLongOption(
                    name: "--\(name)",
                    position: .init(
                        argvIndex: Index<String>(Ordinal(UInt(argvIndex))),
                        byteOffset: .zero
                    ),
                    suggestion: suggestion
                )
            }

            if element.hasPrefix("-") && element.count >= 2 {
                let cluster = String(element.dropFirst())
                if cluster.count == 1 {
                    guard let firstChar = cluster.first else {
                        fatalError("unreachable — cluster.count == 1 guarantees a first element")
                    }
                    if let optionIndex = options.firstIndex(
                        where: { $0.name.short?.character == firstChar }
                    ) {
                        let option = options[optionIndex]
                        guard argvIndex + 1 < argv.count else {
                            throw .missingOptionValue(
                                name: "-\(firstChar)",
                                position: .init(
                                    argvIndex: Index<String>(Ordinal(UInt(argvIndex))),
                                    byteOffset: .zero
                                )
                            )
                        }
                        let valueString = argv[argvIndex + 1]
                        guard option.apply(valueString, &root) else {
                            throw .invalidValue(
                                name: "-\(firstChar)",
                                value: valueString,
                                position: .init(
                                    argvIndex: Index<String>(Ordinal(UInt(argvIndex))),
                                    byteOffset: .zero
                                )
                            )
                        }
                        filledOptionIndices.insert(optionIndex)
                        argvIndex += 2
                        continue
                    }
                    if let manyIndex = optionManies.firstIndex(
                        where: { $0.name.short?.character == firstChar }
                    ) {
                        let many = optionManies[manyIndex]
                        guard argvIndex + 1 < argv.count else {
                            throw .missingOptionValue(
                                name: "-\(firstChar)",
                                position: .init(
                                    argvIndex: Index<String>(Ordinal(UInt(argvIndex))),
                                    byteOffset: .zero
                                )
                            )
                        }
                        let valueString = argv[argvIndex + 1]
                        guard many.append(valueString, &root) else {
                            throw .invalidValue(
                                name: "-\(firstChar)",
                                value: valueString,
                                position: .init(
                                    argvIndex: Index<String>(Ordinal(UInt(argvIndex))),
                                    byteOffset: .zero
                                )
                            )
                        }
                        argvIndex += 2
                        continue
                    }
                    if let flagIndex = flags.firstIndex(
                        where: { $0.name.short?.character == firstChar }
                    ) {
                        flags[flagIndex].apply(&root)
                        argvIndex += 1
                        continue
                    }
                    if let countIndex = flagCounts.firstIndex(
                        where: { $0.name.short?.character == firstChar }
                    ) {
                        flagCounts[countIndex].increment(&root)
                        argvIndex += 1
                        continue
                    }
                    throw .unknownShortOption(
                        name: firstChar,
                        position: .init(
                            argvIndex: Index<String>(Ordinal(UInt(argvIndex))),
                            byteOffset: .zero
                        )
                    )
                }

                for character in cluster {
                    if let flagIndex = flags.firstIndex(
                        where: { $0.name.short?.character == character }
                    ) {
                        flags[flagIndex].apply(&root)
                    } else if let countIndex = flagCounts.firstIndex(
                        where: { $0.name.short?.character == character }
                    ) {
                        flagCounts[countIndex].increment(&root)
                    } else {
                        throw .unknownShortOption(
                            name: character,
                            position: .init(
                                argvIndex: Index<String>(Ordinal(UInt(argvIndex))),
                                byteOffset: .zero
                            )
                        )
                    }
                }
                argvIndex += 1
                continue
            }

            let subcommandName = element
            let subArgv = Array(argv[(argvIndex + 1)...])

            guard
                let binding = group.bindings.first(where: { binding in
                    binding.name == subcommandName || binding.aliases.contains(subcommandName)
                })
            else {
                var candidates: [String] = []
                for binding in group.bindings {
                    candidates.append(binding.name)
                    candidates.append(contentsOf: binding.aliases)
                }
                let suggestion = Command.Diagnostic.Suggestion.closest(
                    to: subcommandName,
                    among: candidates
                )
                throw .unknownSubcommand(
                    name: subcommandName,
                    position: .init(
                        argvIndex: Index<String>(Ordinal(UInt(argvIndex))),
                        byteOffset: .zero
                    ),
                    suggestion: suggestion
                )
            }

            do throws(Command.Error) {
                root = try binding.parse(subArgv: subArgv)
                return
            } catch {
                switch error {
                case .helpRequested:
                    var rendered = ""
                    let fullName: String = {
                        if rootName.isEmpty { return binding.name }
                        return "\(rootName) \(binding.name)"
                    }()
                    binding.appendHelp(to: &rendered, fullCommandName: fullName)
                    throw .helpRequestedForSubcommand(
                        name: binding.name,
                        rendered: rendered
                    )

                default:
                    throw error
                }
            }
        }

        if let defaultBinding = group.bindings.first(where: \.isDefault) {
            do throws(Command.Error) {
                root = try defaultBinding.parse(subArgv: [])
                return
            } catch {
                switch error {
                case .helpRequested:
                    var rendered = ""
                    let fullName: String = {
                        if rootName.isEmpty { return defaultBinding.name }
                        return "\(rootName) \(defaultBinding.name)"
                    }()
                    defaultBinding.appendHelp(to: &rendered, fullCommandName: fullName)
                    throw .helpRequestedForSubcommand(
                        name: defaultBinding.name,
                        rendered: rendered
                    )

                default:
                    throw error
                }
            }
        }

        throw .missingSubcommand(available: group.bindings.map(\.name))
    }

    @usableFromInline
    internal func rootConsumeLongOptionValue(
        name: String,
        inlineValue: String?,
        argvIndex: inout Int
    ) throws(Command.Error) -> String {
        if let inline = inlineValue {
            argvIndex += 1
            return inline
        }
        guard argvIndex + 1 < argv.count else {
            throw .missingOptionValue(
                name: name,
                position: .init(
                    argvIndex: Index<String>(Ordinal(UInt(argvIndex))),
                    byteOffset: .zero
                )
            )
        }
        let value = argv[argvIndex + 1]
        argvIndex += 2
        return value
    }
}
