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

extension Command {
    /// Diagnostic helpers that map ``Command/Error`` to human-readable
    /// messages and canonical Unix exit codes.
    ///
    /// `Command.Diagnostic` is the rendering layer that
    /// ``Command/main(_:initial:arguments:)`` consumes when an
    /// ``Command/Error`` surfaces during parse-or-run. Consumers who
    /// write their own `@main` runner instead of using
    /// ``Command/main(_:initial:arguments:)`` may compose these helpers
    /// directly.
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     var root = try Command.parse(MyCmd.self, from: argv, initial: MyCmd())
    ///     try await root.run()
    /// } catch let error as Command.Error {
    ///     print(Command.Diagnostic.message(for: error))
    ///     Process.exit(Command.Diagnostic.exitCode(for: error))
    /// }
    /// ```
    public enum Diagnostic: Sendable {
        /// Renders a ``Command/Error`` as a human-readable diagnostic
        /// message.
        ///
        /// The format mirrors swift-argument-parser's convention:
        ///
        /// - Help-and-version requests render the carried text directly
        ///   (no `"Error:"` prefix — these are not errors).
        /// - All other cases render with an `"Error: "` prefix followed
        ///   by a single-line description.
        ///
        /// The message is suitable for writing to stderr in the case of
        /// real errors and stdout in the case of help / version
        /// requests; the consuming runner decides which stream to use.
        ///
        /// - Parameter error: The error to render.
        /// - Returns: A human-readable single-line message (or
        ///   pre-rendered help / version text for the
        ///   ``Command/Error/helpRequested`` /
        ///   ``Command/Error/helpRequestedForSubcommand(name:rendered:)`` /
        ///   ``Command/Error/versionRequested(version:)`` cases).
        public static func message(for error: Command.Error) -> String {
            switch error {
            case .helpRequested:
                // Help text rendered upstream by Command.Help; this case
                // surfaces only when the runner itself dispatches the
                // help-render path. Consumers using
                // ``Command/main(_:initial:arguments:)`` see the rendered
                // help text emitted from the runner's pre-exit branch.
                return "Help requested. Pass the schema through Command.Help to render."

            case let .helpRequestedForSubcommand(_, rendered):
                return rendered

            case let .versionRequested(version):
                return version

            case let .exit(_, message):
                return message ?? ""

            case let .argument(argumentError):
                return "Error: \(argumentError)"

            case let .tokenizer(reason, argvIndex):
                return "Error: Tokenizer rejected argv[\(argvIndex)]: \(reason)"

            case let .unknownLongOption(name, _, suggestion):
                if let suggestion {
                    return "Error: Unknown option '\(name)' (did you mean '--\(suggestion)'?)."
                }
                return "Error: Unknown option '\(name)'."

            case let .unknownShortOption(name, _):
                return "Error: Unknown option '-\(name)'."

            case let .missingOptionValue(name, _):
                return "Error: Missing value for option '\(name)'."

            case let .invalidValue(name, value, _):
                return "Error: Invalid value '\(value)' for '\(name)'."

            case let .invalidEnvironmentValue(name, environmentVariable, value):
                return "Error: Invalid value '\(value)' for '\(name)' from environment variable "
                    + "'\(environmentVariable.underlying)'."

            case let .missingPositional(name, _):
                return "Error: Missing expected argument '<\(name)>'."

            case let .unexpectedPositional(value, _):
                return "Error: Unexpected argument '\(value)'."

            case let .validationFailed(reason):
                return "Error: \(reason)"

            case let .unknownSubcommand(name, _, suggestion):
                if let suggestion {
                    return "Error: Unknown subcommand '\(name)' (did you mean '\(suggestion)'?)."
                }
                return "Error: Unknown subcommand '\(name)'."

            case let .missingSubcommand(available):
                if available.isEmpty {
                    return "Error: No subcommand provided."
                }
                return "Error: No subcommand provided. Available subcommands: "
                    + available.joined(separator: ", ") + "."
            }
        }

        /// Maps a ``Command/Error`` to its canonical Unix exit code.
        ///
        /// The mapping follows BSD's `sysexits.h` convention:
        ///
        /// | Case | Exit code | Rationale |
        /// |------|-----------|-----------|
        /// | ``Command/Error/helpRequested`` | `0` | User asked for help; not an error. |
        /// | ``Command/Error/helpRequestedForSubcommand(name:rendered:)`` | `0` | User asked for help. |
        /// | ``Command/Error/versionRequested(version:)`` | `0` | User asked for version; not an error. |
        /// | ``Command/Error/exit(code:message:)`` | the carried code | Consumer-supplied. |
        /// | argv-syntactic errors (unknown / missing / invalid) | `64` (`EX_USAGE`) | Usage error per BSD. |
        /// | ``Command/Error/validationFailed(reason:)`` | `64` (`EX_USAGE`) | Cross-field validation is usage. |
        /// | all others | `1` | General error. |
        ///
        /// - Parameter error: The error to map.
        /// - Returns: The canonical exit code for `error`.
        public static func exitCode(for error: Command.Error) -> Int32 {
            switch error {
            case .helpRequested, .helpRequestedForSubcommand, .versionRequested:
                return 0

            case let .exit(code, _):
                return code

            case .tokenizer,
                 .unknownLongOption,
                 .unknownShortOption,
                 .unknownSubcommand,
                 .missingOptionValue,
                 .invalidValue,
                 .missingPositional,
                 .missingSubcommand,
                 .invalidEnvironmentValue,
                 .unexpectedPositional,
                 .validationFailed:
                // BSD sysexits.h EX_USAGE — argv-syntactic / usage error.
                return 64

            case .argument:
                return 1
            }
        }
    }
}
