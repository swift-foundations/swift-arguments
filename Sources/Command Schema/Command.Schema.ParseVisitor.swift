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
    /// The schema-driven argv parser, implemented as a
    /// ``Command/Schema/Visitor``.
    ///
    /// `ParseVisitor<Root>` collects schema-bound parse entries during a
    /// single pass over the schema's nodes, then applies the L1 token
    /// stream against the accumulated entries to populate a `Root`
    /// instance. The two-pass shape (visit-to-collect, finalize-to-apply)
    /// lets each `visit(...)` method see the static value type `V` of
    /// its node and capture a typed value-parser closure that erases
    /// `V` only at the storage layer (per-entry closures over `Self.Root`).
    ///
    /// ## Token-dispatch policy
    ///
    /// The walker consumes tokens left-to-right. Each token classifies
    /// against the accumulated entries:
    ///
    /// - `.long(name)` matches an option or flag declared with `.long(name)`.
    ///   If the next token is `.value(s)`, that string is parsed for the
    ///   option. For a flag, the next-token-is-value form is rejected.
    /// - `.shortCluster(s)` matches single-character entries when `s` is
    ///   one character long, or treats the cluster as concatenated flags
    ///   when the schema declares each character as a flag. For v1, the
    ///   short-form policy is simple — single-character `shortCluster(c)`
    ///   matches a `.short(c)` option / flag entry; longer clusters
    ///   raise `unknownShortOption` (a v2+ extension can re-tokenize).
    /// - `.value(s)` directly follows an option token; standalone
    ///   value tokens are not produced by ``Argument/Tokenizer/Default``.
    /// - `.positional(s)` consumes the next positional entry in
    ///   declaration order.
    /// - `.endOfOptions` switches the remaining tokens to all-positional.
    public struct ParseVisitor<Root: Sendable>: Sendable {
        /// The token stream produced by ``Argument/Tokenizer/Default``.
        @usableFromInline
        internal let tokens: [Argument.Token]

        /// The root command instance the visitor mutates.
        public var root: Root

        /// Accumulated positional entries in declaration order.
        @usableFromInline
        internal var positionals: [PositionalEntry] = []

        /// Accumulated array-positional ("Many") entry. At most one per
        /// schema is supported — a second declaration creates ambiguous
        /// greedy consumption and is rejected at parse time.
        @usableFromInline
        internal var positionalMany: PositionalManyEntry?

        /// Accumulated option entries in declaration order.
        @usableFromInline
        internal var options: [OptionEntry] = []

        /// Accumulated repeatable-option ("Many") entries in declaration
        /// order. Matched via a separate dispatch path because the
        /// semantic differs (append vs. overwrite).
        @usableFromInline
        internal var optionManies: [OptionManyEntry] = []

        /// Indices into ``options`` whose values were supplied by argv.
        ///
        /// The env-var fallback pass at the tail of ``finalize()`` skips
        /// any option in this set — argv-supplied values take precedence
        /// over env-var values per the standard precedence order
        /// (cmdline > env > defaults).
        @usableFromInline
        internal var filledOptionIndices: Set<Int> = []

        /// Accumulated flag entries in declaration order.
        @usableFromInline
        internal var flags: [FlagEntry] = []

        /// Accumulated count-flag entries in declaration order.
        @usableFromInline
        internal var flagCounts: [FlagCountEntry] = []

        /// Accumulated inverted-flag entries in declaration order. Each
        /// entry registers two long-option strings on the argv dispatch
        /// path.
        @usableFromInline
        internal var flagInverteds: [FlagInvertedEntry] = []

        /// Accumulated enumerable-flag entries in declaration order.
        @usableFromInline
        internal var flagEnumerables: [FlagEnumerableEntry] = []

        /// The subcommand-group entry, if any. At most one Group per
        /// schema is supported in v1 (per the design doc §3.15 v1 scope).
        @usableFromInline
        internal var subcommandGroup: SubcommandGroupEntry?

        /// The original raw argv elements. For subcommand dispatch, the
        /// visitor needs the original argv slice following the
        /// subcommand-name token to feed the sub-parse pass.
        @usableFromInline
        internal let argv: [String]

        /// The root command's CLI name (from `Root.configuration.name`)
        /// for sub-help USAGE-line rendering. Empty when not supplied —
        /// callers using the legacy `init(tokens:root:)` form do not need
        /// subcommand support, so the root name defaults to empty.
        @usableFromInline
        internal let rootName: String

        /// The root command's version string (from
        /// `Root.configuration.version`) used to intercept `--version`.
        ///
        /// Empty when not supplied — in that case `--version` is treated
        /// as an unknown option (matching swift-argument-parser's
        /// behaviour: opt-in by setting `configuration.version`).
        @usableFromInline
        internal let rootVersion: String

        /// Creates a parse visitor.
        ///
        /// Legacy initializer for non-subcommand schemas — argv slice is
        /// not threaded, so subcommand dispatch will throw
        /// ``Command/Error/missingSubcommand(available:)`` if the schema
        /// declares a Group. The `rootVersion` is empty, so `--version`
        /// is not intercepted under this form.
        @inlinable
        public init(tokens: [Argument.Token], root: Root) {
            self.tokens = tokens
            self.argv = []
            self.rootName = ""
            self.rootVersion = ""
            self.root = root
        }

        /// Creates a parse visitor with the source argv and root-command
        /// name recorded alongside the token stream. Used by
        /// ``Command/parse(_:from:initial:)`` to support subcommand
        /// dispatch — the sub-parse pass needs the original argv elements
        /// following the subcommand name, and the root name appears in
        /// rendered sub-help. The `rootVersion` parameter, when non-empty,
        /// enables interception of `--version` per
        /// ``Command/Error/versionRequested(version:)``.
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
    /// A type-erased positional schema entry.
    @usableFromInline
    internal struct PositionalEntry: Sendable {
        /// The schema-side name (used in diagnostics).
        @usableFromInline let name: String
        /// Applies a single argv-string value to the root via the
        /// captured KeyPath.
        @usableFromInline let apply: @Sendable (String, inout Root) -> Bool
    }

    /// A type-erased array-positional ("Many") schema entry.
    ///
    /// Stored alongside ``positionals`` to support `rest`-positional
    /// shape: after every fixed-arity positional has been consumed in
    /// declaration order, remaining positional argv tokens stream into
    /// the (at most one) array-positional entry, each appending one
    /// parsed value to the bound `[V]` field.
    @usableFromInline
    internal struct PositionalManyEntry: Sendable {
        /// The schema-side name (used in diagnostics).
        @usableFromInline let name: String
        /// The arity bound the entry enforces at finalization.
        @usableFromInline let arity: Argument.Arity
        /// Appends one argv-string value to the bound array.
        @usableFromInline let append: @Sendable (String, inout Root) -> Bool
        /// Reads the current count of accumulated values (for
        /// finalization-time arity validation).
        @usableFromInline let count: @Sendable (Root) -> Int
    }

    /// A type-erased option schema entry.
    @usableFromInline
    internal struct OptionEntry: Sendable {
        /// The L1 name forms.
        @usableFromInline let name: Argument.Name
        /// Applies a single argv-string value to the root.
        @usableFromInline let apply: @Sendable (String, inout Root) -> Bool
        /// The optional process-environment variable name that supplies
        /// a fallback value when the option is not provided on argv.
        @usableFromInline let environment: Argument.Environment.Variable.Name?
    }

    /// A type-erased repeatable-option ("Many") schema entry.
    ///
    /// Unlike a single-valued ``OptionEntry``, each occurrence on argv
    /// appends a new parsed value to the bound `[V]` field rather than
    /// overwriting a single-value slot. Stored alongside ``options``
    /// but matched via a separate dispatch path so the append semantics
    /// are explicit.
    @usableFromInline
    internal struct OptionManyEntry: Sendable {
        /// The L1 name forms.
        @usableFromInline let name: Argument.Name
        /// The arity bound the entry enforces at finalization.
        @usableFromInline let arity: Argument.Arity
        /// Appends one argv-string value to the bound array.
        @usableFromInline let append: @Sendable (String, inout Root) -> Bool
        /// Reads the current count of accumulated occurrences (for
        /// finalization-time arity validation).
        @usableFromInline let count: @Sendable (Root) -> Int
    }

    /// A type-erased flag schema entry.
    @usableFromInline
    internal struct FlagEntry: Sendable {
        /// The L1 name forms.
        @usableFromInline let name: Argument.Name
        /// Writes `true` to the bound Bool field.
        @usableFromInline let apply: @Sendable (inout Root) -> Void
    }

    /// A type-erased count-flag schema entry.
    ///
    /// Each occurrence of the flag (long form or short-cluster
    /// character) increments the bound `Int` field by one.
    @usableFromInline
    internal struct FlagCountEntry: Sendable {
        /// The L1 name forms.
        @usableFromInline let name: Argument.Name
        /// Increments the bound counter by one.
        @usableFromInline let increment: @Sendable (inout Root) -> Void
    }

    /// A type-erased inverted-flag schema entry.
    ///
    /// Carries both derived long-option strings — the "true" form and
    /// the "false" form — so the argv dispatcher can match either and
    /// write the corresponding `Bool` value to the bound field.
    @usableFromInline
    internal struct FlagInvertedEntry: Sendable {
        /// The long-option string that selects `true`.
        @usableFromInline let trueName: String
        /// The long-option string that selects `false`.
        @usableFromInline let falseName: String
        /// Writes the supplied `Bool` to the bound field.
        @usableFromInline let apply: @Sendable (Bool, inout Root) -> Void
    }

    /// A type-erased enumerable-flag schema entry.
    ///
    /// Each enum case registers one long-option name; argv match writes
    /// the corresponding enum case to the bound field via
    /// ``casesByLongName``. Last-wins semantics — the rightmost match
    /// overwrites previous matches.
    @usableFromInline
    internal struct FlagEnumerableEntry: Sendable {
        /// Maps each registered long-option name to the apply closure
        /// that writes the matching enum case to the bound field.
        @usableFromInline let casesByLongName: [String: @Sendable (inout Root) -> Void]
    }

    // swiftlint:disable no_any_protocol_existential
    // reason: subcommand-binding heterogeneity is load-bearing — each
    // binding carries a distinct `Sub` generic; the existential is the
    // only shape that holds the heterogeneous list at this layer.

    /// A type-erased subcommand-group schema entry.
    @usableFromInline
    internal struct SubcommandGroupEntry: Sendable {
        /// The subcommand bindings in declaration order.
        @usableFromInline let bindings: [any Command.Subcommand.Binding<Root>]
    }

    // swiftlint:enable no_any_protocol_existential
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
        // v1 supports at most one subcommand group per schema; a second
        // visit overwrites the first (defensive — the result-builder
        // grammar admits this, but it's an unusual shape).
        self.subcommandGroup = SubcommandGroupEntry(bindings: group.bindings)
    }

    public mutating func visit<G: Sendable & Equatable>(
        optionGroup: Command.OptionGroup<Root, G>
    ) throws(Command.Error) {
        // Walk the group's sub-schema through a forwarding visitor that
        // emits Root-rooted entries whose apply closures chain through
        // the group's outer keyPath. Each forwarder entry is then
        // appended to this visitor's per-kind accumulator so the
        // standard finalize() loop dispatches argv tokens against the
        // flattened entry list uniformly.
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
    /// After all schema nodes have been visited, walk the L1 token stream
    /// and dispatch tokens against the accumulated entries.
    ///
    /// - Throws: ``Command/Error`` on any tokenize/dispatch failure.
    public mutating func finalize() throws(Command.Error) {
        // Subcommand-dispatch fast path: when the schema declares a
        // ``Command/Subcommand/Group``, the parent command's argv layout is
        // restricted to "[global flags/options] <subcommand> [...sub-argv]"
        // per the v1 dispatch model. The first non-flag argv element is
        // the subcommand name; everything after is sub-argv handed to the
        // matched binding's `parse(subArgv:)` (which itself runs a full
        // sub-parse pass against the sub-command's schema).
        //
        // v1 simplification: the root-level Group precludes root-level
        // positionals. Root-level flags/options are still permitted
        // before the subcommand name, and `--help` / `-h` at the root
        // raises ``Command/Error/helpRequested`` for top-level help.
        if let group = subcommandGroup {
            try dispatchSubcommand(group: group)
            return
        }

        var positionalCursor: Int = 0
        var index: Int = 0
        var afterEndOfOptions = false

        while index < tokens.count {
            let token = tokens[index]

            if afterEndOfOptions {
                // All tokens after -- are positionals.
                switch token.kind {
                case let .positional(string):
                    try applyPositional(string: string, cursor: &positionalCursor, token: token)

                case .endOfOptions:
                    // A second -- is malformed but tolerated.
                    break

                default:
                    // Token shapes other than .positional shouldn't appear
                    // after .endOfOptions per the tokenizer contract; treat
                    // as positional opportunistically.
                    if case let .value(string) = token.kind {
                        try applyPositional(
                            string: string, cursor: &positionalCursor, token: token
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

            case let .long(name):
                try applyLong(name: name, tokenIndex: &index, token: token)

            case let .shortCluster(cluster):
                // POSIX-vs-numeric heuristic: when the cluster's first
                // character is a digit, the schema declares no short
                // option / flag / count-flag for that digit, AND a
                // positional slot is still pending, the argv element is
                // a negative-number positional (e.g. `seq -5 5`, `bc -2`,
                // `-3.14`) — not an option. Re-route the token (plus any
                // glued .value sharing the same source range) as a
                // positional value reconstructed from the leading `-`.
                //
                // Schema-explicit-wins: when the schema DOES declare a
                // short binding for the digit (e.g. a `-5` flag), the
                // heuristic suppresses and dispatch proceeds via
                // ``applyShortCluster``.
                if let firstChar = cluster.first,
                   firstChar.isASCII, firstChar.isNumber,
                   !hasShortBinding(for: firstChar),
                   (positionalCursor < positionals.count) || (positionalMany != nil) {
                    // Reconstruct the positional value: leading `-`, the
                    // cluster, and any glued .value carrying the
                    // remainder of the source argv element.
                    var positionalString = "-" + cluster
                    var advance = 1
                    if index + 1 < tokens.count,
                       case let .value(continuation) = tokens[index + 1].kind,
                       tokens[index + 1].range == token.range {
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

            case let .positional(string):
                try applyPositional(string: string, cursor: &positionalCursor, token: token)
                index += 1

            case .value:
                // A bare .value not preceded by an option token is malformed
                // for the v1 surface; treat as a positional (gnuly tolerant).
                if case let .value(string) = token.kind {
                    try applyPositional(string: string, cursor: &positionalCursor, token: token)
                }
                index += 1

            case .separator:
                // Tokenizer emits .long(name)+.value(v) for --name=v; bare
                // .separator should not appear. Skip if encountered.
                index += 1
            }
        }

        // After argv consumption, apply the env-var fallback pass for
        // any option whose `environment` was declared and whose
        // value was not supplied by argv. argv precedence is preserved:
        // options recorded in `filledOptionIndices` are skipped.
        try applyEnvironmentVariableFallbacks()

        // Verify all required positionals have been bound.
        if positionalCursor < positionals.count {
            let missing = positionals[positionalCursor]
            throw .missingPositional(
                name: missing.name,
                position: .init(argvIndex: .zero, byteOffset: .zero)
            )
        }

        // Verify the array-positional ("Many"), if any, satisfies its
        // declared arity bounds.
        try validatePositionalManyArity()

        // Verify each repeatable-option ("Many") satisfies its declared
        // arity bounds (count of occurrences).
        try validateOptionManyArities()
    }

    /// Applies env-var fallbacks for any option not filled by argv.
    ///
    /// For each ``OptionEntry`` whose `environment` is non-nil
    /// and whose index is not in ``filledOptionIndices``, reads the
    /// process environment via ``Environment/Read`` and, when the value
    /// is set, runs the entry's apply closure. argv-supplied values
    /// take precedence; an unset env-var leaves the option's field at
    /// its `initial` value (consumer's static default).
    ///
    /// - Throws: ``Command/Error/invalidEnvironmentValue(name:environment:value:)``
    ///   when an env-var value fails ``Argument/Codable`` conversion.
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

    /// Renders an ``Argument/Name`` to its public CLI form for
    /// diagnostics (e.g., `"--count"`, `"-c"`, `"-c, --count"`).
    @usableFromInline
    internal static func publicName(for name: Argument.Name) -> String {
        switch name {
        case let .short(short):
            return "-\(short.character)"

        case let .long(long):
            return "--\(long.string)"

        case let .both(short, long):
            return "-\(short.character), --\(long.string)"
        }
    }

    // MARK: - Per-token dispatchers

    @usableFromInline
    internal mutating func applyPositional(
        string: String,
        cursor: inout Int,
        token: Argument.Token
    ) throws(Command.Error) {
        // Single-positional cursor first: consume one of the fixed
        // declarations in order.
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

        // Otherwise, the value streams into the rest-positional ("Many")
        // entry if one is declared. The "exactly one Many, after every
        // single positional" composition rule is enforced at visit time;
        // here we simply append to the rest-positional bucket.
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

        // No fixed positional slot AND no rest-positional declared:
        // the argv supplied surplus values.
        throw .unexpectedPositional(
            value: string,
            position: position(from: token)
        )
    }

    /// Validates the array-positional entry's arity bounds.
    ///
    /// Called from ``finalize()`` after argv consumption. The error
    /// surfaced when the declared arity bounds are violated is
    /// ``Command/Error/validationFailed(reason:)``.
    @usableFromInline
    internal mutating func validatePositionalManyArity() throws(Command.Error) {
        guard let many = positionalMany else { return }
        let count = many.count(root)
        try Self.checkArityBounds(arity: many.arity, count: count, name: many.name, kind: "positional")
    }

    /// Validates each repeatable-option entry's arity bounds.
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

    /// Compares an observed `count` against an ``Argument/Arity`` bound
    /// and throws ``Command/Error/validationFailed(reason:)`` on
    /// violation. Static helper so the same logic serves both
    /// positional and option array-bound validation.
    @usableFromInline
    internal static func checkArityBounds(
        arity: Argument.Arity,
        count: Int,
        name: String,
        kind: String
    ) throws(Command.Error) {
        switch arity {
        case let .exactly(target):
            guard count == target else {
                throw .validationFailed(
                    reason: "Expected exactly \(target) value(s) for \(kind) '\(name)', got \(count)."
                )
            }
        case let .atMost(maximum):
            guard count <= maximum else {
                throw .validationFailed(
                    reason: "Expected at most \(maximum) value(s) for \(kind) '\(name)', got \(count)."
                )
            }
        case let .atLeast(minimum):
            guard count >= minimum else {
                throw .validationFailed(
                    reason: "Expected at least \(minimum) value(s) for \(kind) '\(name)', got \(count)."
                )
            }
        case let .range(range):
            guard range.contains(count) else {
                throw .validationFailed(
                    reason: "Expected \(range.lowerBound)…\(range.upperBound) value(s) for \(kind) "
                        + "'\(name)', got \(count)."
                )
            }
        case .count:
            // .count arity is a count-flag concept; not meaningful for
            // value-bearing array entries. Skip silently.
            break
        }
    }

    @usableFromInline
    internal mutating func applyLong(
        name: String,
        tokenIndex: inout Int,
        token: Argument.Token
    ) throws(Command.Error) {
        // Try options first.
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

        // Then repeatable options.
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

        // Then flags.
        if let flagIndex = flags.firstIndex(where: { $0.name.long?.string == name }) {
            flags[flagIndex].apply(&root)
            tokenIndex += 1
            return
        }

        // Then count-flags (long-form occurrence increments by one;
        // short-cluster increments are handled in applyShortCluster).
        if let countIndex = flagCounts.firstIndex(where: { $0.name.long?.string == name }) {
            flagCounts[countIndex].increment(&root)
            tokenIndex += 1
            return
        }

        // Then inverted-flag pairs (matches the "true" or "false" name).
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

        // Then enumerable-flag cases (each case registers its own
        // long-option name; last-wins semantics).
        for entry in flagEnumerables {
            if let apply = entry.casesByLongName[name] {
                apply(&root)
                tokenIndex += 1
                return
            }
        }

        // Built-in help requests.
        if name == "help" {
            throw .helpRequested
        }

        // Built-in version request — intercepted only when the root
        // command declares a non-empty `configuration.version`. With an
        // empty version string `--version` falls through to the unknown-
        // option throw (matching swift-argument-parser's opt-in shape).
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

    /// Consumes the value token immediately following an option token.
    ///
    /// Factored out of ``applyLong(name:tokenIndex:token:)`` so the
    /// single-option, repeatable-option, and short-option paths share
    /// the same "expect a value next" logic without duplication.
    /// Returns the value string and advances `tokenIndex` past it.
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
        case let .value(string):
            tokenIndex = valueIndex + 1
            return string

        case let .positional(string):
            // GNU-style `--option value` form; the tokenizer emits
            // .positional(value) for the next argv element.
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
        // POSIX 12.2 disambiguation: an argv element shaped `-Xrest` tokenizes
        // as .shortCluster("X") + .value("rest") (Guideline 6). The value belongs
        // to X iff X is a value-taking option; otherwise the rest is additional
        // cluster characters (Guideline 5 flag clustering, e.g. `-vvv`). Schema-
        // aware fold splices the glued .value onto the cluster when the first
        // char doesn't bind a value-taking option.
        var effectiveCluster = cluster
        var spliceAdvance = 0
        if cluster.count == 1,
           tokenIndex + 1 < tokens.count,
           case let .value(continuation) = tokens[tokenIndex + 1].kind,
           tokens[tokenIndex + 1].range == token.range {
            let firstChar = cluster.first!  // safe — count == 1
            let isValueOption = options.contains { $0.name.short?.character == firstChar }
                || optionManies.contains { $0.name.short?.character == firstChar }
            if !isValueOption {
                effectiveCluster = cluster + continuation
                spliceAdvance = 1
            }
        }

        // v1 short-form policy: a single-character cluster matches a
        // short option or short flag. Multi-character clusters require
        // either an exact short-cluster name match or are rejected.
        if effectiveCluster.count == 1 {
            let firstChar = effectiveCluster.first!  // safe — count == 1

            // Try short options.
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

            // Then short repeatable options.
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

            // Try short flags.
            if let flagIndex = flags.firstIndex(
                where: { $0.name.short?.character == firstChar }
            ) {
                flags[flagIndex].apply(&root)
                tokenIndex += 1
                return
            }

            // Then short count-flags (single-character form).
            if let countIndex = flagCounts.firstIndex(
                where: { $0.name.short?.character == firstChar }
            ) {
                flagCounts[countIndex].increment(&root)
                tokenIndex += 1
                return
            }

            // Help shorthand: -h.
            if firstChar == "h" {
                throw .helpRequested
            }

            throw .unknownShortOption(
                name: firstChar,
                position: position(from: token)
            )
        }

        // Multi-character cluster: every character must match a short flag
        // OR a short count-flag character. If any character maps to a
        // value-taking option, the cluster is ambiguous and v1 rejects it.
        // Count-flag characters in a cluster (`-vvv`) each increment the
        // bound counter by one.
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

    // MARK: - Helpers

    @usableFromInline
    internal func position(from token: Argument.Token) -> Argument.Position {
        Argument.Position(
            argvIndex: .zero,
            byteOffset: .init(fromZero: token.range.start)
        )
    }

    /// Checks whether the schema declares any short binding (option,
    /// repeatable option, flag, or count-flag) bound to `character`.
    ///
    /// Used by the numeric-positional dispatch heuristic in
    /// ``finalize()`` to detect "schema-explicit-wins" cases — when the
    /// schema declares a short binding for a digit (e.g. `-5` as a Bool
    /// flag), the negative-number positional heuristic suppresses so
    /// the dispatched short binding wins.
    @usableFromInline
    internal func hasShortBinding(for character: Character) -> Bool {
        if options.contains(where: { $0.name.short?.character == character }) { return true }
        if optionManies.contains(where: { $0.name.short?.character == character }) { return true }
        if flags.contains(where: { $0.name.short?.character == character }) { return true }
        if flagCounts.contains(where: { $0.name.short?.character == character }) { return true }
        return false
    }

    /// Collects every long-option name declared by the schema for
    /// suggestion-matching at the unknown-option throw sites.
    ///
    /// Includes the long forms of every option, repeatable option, flag,
    /// count-flag, and enumerable-flag entry, plus both names of each
    /// inverted-flag pair. The built-in `"help"` and `"version"` names
    /// (the latter only when ``rootVersion`` is non-empty) are also
    /// included — they are valid declared names from the user's point of
    /// view and should be suggested when an unknown name is a near miss.
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

    // MARK: - Subcommand dispatch

    /// Dispatches a subcommand group against the source argv.
    ///
    /// v1 dispatch model: the first non-flag argv element is the
    /// subcommand name; everything after is sub-argv handed to the
    /// matched binding's `parse(subArgv:)`. Root-level flags / options
    /// before the subcommand name are honoured (consumed against the
    /// accumulated `flags` / `options` entries); a root-level `--help`
    /// / `-h` raises ``Command/Error/helpRequested``.
    ///
    /// Per the v1 simplification documented in
    /// ``Command/Schema/ParseVisitor/finalize()``, a schema declaring a
    /// subcommand group has no root-level positionals — the first
    /// "positional"-shaped argv element IS the subcommand name.
    @usableFromInline
    internal mutating func dispatchSubcommand(
        group: SubcommandGroupEntry
    ) throws(Command.Error) {
        // Walk argv looking for the first element that is neither a
        // long option (--*) nor a short option (-*). Along the way,
        // consume root-level flags / options against the visitor's
        // accumulated entries. The subcommand name argv index is
        // captured for slicing.
        var argvIndex = 0
        while argvIndex < argv.count {
            let element = argv[argvIndex]

            // Top-level help shorthand and explicit help request.
            if element == "--help" || element == "-h" {
                throw .helpRequested
            }

            // Top-level version request — intercepted only when the root
            // command declares a non-empty `configuration.version`.
            if element == "--version", !rootVersion.isEmpty {
                throw .versionRequested(version: rootVersion)
            }

            // Long option (with or without =value form).
            if element.hasPrefix("--") {
                let trimmed = String(element.dropFirst(2))
                let (name, inlineValue): (String, String?) = {
                    if let eq = trimmed.firstIndex(of: "=") {
                        return (String(trimmed[..<eq]), String(trimmed[trimmed.index(after: eq)...]))
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
                            position: .init(argvIndex: Index<String>(Ordinal(UInt(argvIndex))), byteOffset: .zero)
                        )
                    }
                    filledOptionIndices.insert(optionIndex)
                    continue
                }

                if let manyIndex = optionManies.firstIndex(where: { $0.name.long?.string == name }) {
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
                            position: .init(argvIndex: Index<String>(Ordinal(UInt(argvIndex))), byteOffset: .zero)
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
                    position: .init(argvIndex: Index<String>(Ordinal(UInt(argvIndex))), byteOffset: .zero),
                    suggestion: suggestion
                )
            }

            // Short option / flag cluster (single-character cluster only
            // is supported at the root layer in v1; complex clusters
            // belong to the sub-parse).
            if element.hasPrefix("-") && element.count >= 2 {
                let cluster = String(element.dropFirst())
                if cluster.count == 1 {
                    let firstChar = cluster.first!  // safe — count == 1
                    if let optionIndex = options.firstIndex(
                        where: { $0.name.short?.character == firstChar }
                    ) {
                        let option = options[optionIndex]
                        guard argvIndex + 1 < argv.count else {
                            throw .missingOptionValue(
                                name: "-\(firstChar)",
                                position: .init(argvIndex: Index<String>(Ordinal(UInt(argvIndex))), byteOffset: .zero)
                            )
                        }
                        let valueString = argv[argvIndex + 1]
                        guard option.apply(valueString, &root) else {
                            throw .invalidValue(
                                name: "-\(firstChar)",
                                value: valueString,
                                position: .init(argvIndex: Index<String>(Ordinal(UInt(argvIndex))), byteOffset: .zero)
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
                                position: .init(argvIndex: Index<String>(Ordinal(UInt(argvIndex))), byteOffset: .zero)
                            )
                        }
                        let valueString = argv[argvIndex + 1]
                        guard many.append(valueString, &root) else {
                            throw .invalidValue(
                                name: "-\(firstChar)",
                                value: valueString,
                                position: .init(argvIndex: Index<String>(Ordinal(UInt(argvIndex))), byteOffset: .zero)
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
                        position: .init(argvIndex: Index<String>(Ordinal(UInt(argvIndex))), byteOffset: .zero)
                    )
                }
                // Multi-character cluster at root: every char must be a
                // (single-char) flag or count-flag. Value-taking options
                // are not permitted inside a cluster.
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
                            position: .init(argvIndex: Index<String>(Ordinal(UInt(argvIndex))), byteOffset: .zero)
                        )
                    }
                }
                argvIndex += 1
                continue
            }

            // Otherwise: this is the subcommand name.
            let subcommandName = element
            let subArgv = Array(argv[(argvIndex + 1)...])

            // Match the binding (primary name or alias).
            guard let binding = group.bindings.first(where: { binding in
                binding.name == subcommandName || binding.aliases.contains(subcommandName)
            }) else {
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
                    position: .init(argvIndex: Index<String>(Ordinal(UInt(argvIndex))), byteOffset: .zero),
                    suggestion: suggestion
                )
            }

            // Dispatch sub-parse. If the sub-parse raises .helpRequested,
            // re-route through .helpRequestedForSubcommand with rendered
            // sub-help text so callers can distinguish.
            do {
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

        // argv exhausted without a subcommand name. If the group
        // declares a default binding, dispatch it with empty sub-argv;
        // otherwise surface the missing-subcommand error.
        if let defaultBinding = group.bindings.first(where: \.isDefault) {
            do {
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

    /// Resolves a long-option's value at the root level of a subcommand-
    /// dispatch parse — either inline (`--name=value`) or as the next
    /// argv element (`--name value`).
    ///
    /// Advances `argvIndex` past the consumed element(s) — by one for
    /// the inline form, by two for the next-element form. Mirrors
    /// ``consumeOptionValue`` but operates over raw argv rather than
    /// L1 tokens because the subcommand-dispatch path walks the source
    /// argv directly.
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
                position: .init(argvIndex: Index<String>(Ordinal(UInt(argvIndex))), byteOffset: .zero)
            )
        }
        let value = argv[argvIndex + 1]
        argvIndex += 2
        return value
    }
}
