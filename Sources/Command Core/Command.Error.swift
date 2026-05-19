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

public import Argument_Primitives

extension Command {
    /// The typed-throws error domain for command-level failures.
    ///
    /// `Command.Error` is the top-level typed-error enum for the L3
    /// argument-parsing pipeline. It wraps L1 ``Argument/Error`` for
    /// pure-argv failures and adds command-orchestration cases (tokenizer
    /// errors, schema mismatches, validation failures, missing
    /// subcommand) that L1 does not model.
    ///
    /// Each case is self-contained — diagnostic emission and exit-code
    /// mapping live downstream; this enum is the structural carrier per
    /// [API-ERR-001].
    public enum Error: Swift.Error, Sendable, Hashable, Equatable {
        /// An L1 ``Argument/Error`` raised during schema-driven parsing.
        case argument(Argument.Error)

        /// The L2 argv tokenizer rejected an argv element. The wrapped
        /// `String` carries the source argv element and a description of
        /// the violation; the L3 tokenizer maps L2 errors here.
        case tokenizer(reason: String, argvIndex: Swift.Int)

        /// A long option name was supplied that no schema declared.
        ///
        /// `suggestion` carries the closest-edit-distance declared
        /// long-option name when a near match exists (see
        /// ``Command/Diagnostic/Suggestion/closest(to:among:)``); `nil`
        /// when no candidate name is within the suggestion threshold. The
        /// suggestion is the bare name (without the `--` prefix).
        case unknownLongOption(name: String, position: Argument.Position, suggestion: String?)

        /// A short option name was supplied that no schema declared.
        case unknownShortOption(name: Character, position: Argument.Position)

        /// An option needs a value but the value was missing.
        case missingOptionValue(name: String, position: Argument.Position)

        /// An option's value could not be parsed via ``Argument/Codable``.
        case invalidValue(name: String, value: String, position: Argument.Position)

        /// A value sourced from a process-environment variable could not
        /// be parsed via ``Argument/Codable``.
        ///
        /// Diagnostics emit this case when an option declared with an
        /// `environmentVariable:` fallback receives a value from
        /// ``Argument/Environment/Variable/Name`` lookup that
        /// ``Argument/Codable`` rejects. The `name` carries the option's
        /// public form (e.g. `"--count"`); `environmentVariable` carries
        /// the env-var name read (e.g. `"MYAPP_COUNT"`); `value` carries
        /// the raw env-var string that failed conversion. Unlike
        /// ``invalidValue(name:value:position:)`` there is no
        /// ``Argument/Position`` because the value originates outside
        /// argv — its source is the process environment, not a token
        /// slot.
        case invalidEnvironmentValue(
            name: String,
            environmentVariable: Argument.Environment.Variable.Name,
            value: String
        )

        /// A required positional argument was not supplied.
        case missingPositional(name: String, position: Argument.Position)

        /// More positional values were supplied than the schema declared.
        case unexpectedPositional(value: String, position: Argument.Position)

        /// Cross-field validation rejected an otherwise-parseable argv.
        case validationFailed(reason: String)

        /// The user requested help — not strictly an error but routed
        /// through the error path so callers can render help and exit
        /// cleanly via the same channel.
        case helpRequested

        /// The user requested the command's version — not strictly an
        /// error but routed through the error path so callers can render
        /// the version string and exit cleanly via the same channel.
        ///
        /// `--version` is intercepted only when the root command's
        /// ``Command/Configuration/version`` is non-empty; with an empty
        /// version string the option is treated as unknown (matching
        /// swift-argument-parser's behaviour: a `--version` flag that the
        /// schema does not declare and the configuration does not enable
        /// is just an unknown option).
        case versionRequested(version: String)

        /// The user supplied a subcommand name that no
        /// ``Command/Subcommand/Group`` binding declared. The wrapped
        /// `String` is the offending argv element; `position` cites the
        /// argv slot where the unknown name appeared. `suggestion` carries
        /// the closest-edit-distance declared subcommand name when a near
        /// match exists (see
        /// ``Command/Diagnostic/Suggestion/closest(to:among:)``); `nil`
        /// when no candidate name is within the suggestion threshold.
        case unknownSubcommand(name: String, position: Argument.Position, suggestion: String?)

        /// The user requested help for a specific subcommand. The
        /// wrapped `String` carries pre-rendered help text for that
        /// subcommand; callers route this case identically to
        /// ``helpRequested`` (print the text and exit cleanly).
        ///
        /// The split into a separate case lets callers distinguish
        /// "top-level help" from "subcommand help" diagnostically — the
        /// rendered output is already baked in either way.
        case helpRequestedForSubcommand(name: String, rendered: String)

        /// A schema declared a ``Command/Subcommand/Group`` but argv
        /// supplied no subcommand name (argv was empty or only contained
        /// global flags that the schema doesn't declare). The wrapped
        /// `[String]` carries the declared subcommand names for
        /// diagnostic output.
        case missingSubcommand(available: [String])

        /// A typed exit request raised by command bodies that need to
        /// thread a custom exit code (and optional message) through the
        /// typed-throws path without escaping to the platform `exit(...)`
        /// intrinsic.
        ///
        /// `Command.Error.exit(code:message:)` lets consumers signal
        /// process termination structurally — the `@main` runner maps
        /// this case to the OS exit syscall with the carried `code`
        /// (forwarded through ``Command/Exit/code``), printing the
        /// optional `message` to stderr beforehand. Routing termination
        /// through the typed-throws surface keeps `run()` callable from
        /// tests (which can `catch` the case and assert on it) and
        /// preserves [API-ERR-001] typed-throws end-to-end.
        ///
        /// ## Example
        ///
        /// ```swift
        /// mutating func run() async throws(Command.Error) {
        ///     guard validateInput(self) else {
        ///         throw .exit(code: 2, message: "Invalid input.")
        ///     }
        ///     // ... main work ...
        /// }
        /// ```
        ///
        /// The runner translates `.exit(code: 0, ...)` as clean
        /// termination (matching ``Command/Exit/success``); non-zero
        /// codes follow the consumer's convention.
        case exit(code: Int32, message: String? = nil)
    }
}
