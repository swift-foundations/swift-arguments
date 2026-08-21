internal import Tagged_Primitives

extension Command {

    public enum Diagnostic: Sendable {}
}

extension Command.Diagnostic {

    public static func message(for error: Command.Error) -> String {
        switch error {
        case .helpRequested:

            return "Help requested. Pass the schema through Command.Help to render."

        case .helpRequestedForSubcommand(_, let rendered):
            return rendered

        case .versionRequested(let version):
            return version

        case .exit(_, let message):
            return message ?? ""

        case .argument(let argumentError):
            return "Error: \(argumentError)"

        case .tokenizer(let reason, let argvIndex):
            return "Error: Tokenizer rejected argv[\(argvIndex)]: \(reason)"

        case .unknownLongOption(let name, _, let suggestion):
            if let suggestion {
                return "Error: Unknown option '\(name)' (did you mean '--\(suggestion)'?)."
            }
            return "Error: Unknown option '\(name)'."

        case .unknownShortOption(let name, _):
            return "Error: Unknown option '-\(name)'."

        case .missingOptionValue(let name, _):
            return "Error: Missing value for option '\(name)'."

        case .invalidValue(let name, let value, _):
            return "Error: Invalid value '\(value)' for '\(name)'."

        case .invalidEnvironmentValue(let name, let environment, let value):
            return "Error: Invalid value '\(value)' for '\(name)' from environment variable "
                + "'\(environment.underlying)'."

        case .missingPositional(let name, _):
            return "Error: Missing expected argument '<\(name)>'."

        case .unexpectedPositional(let value, _):
            return "Error: Unexpected argument '\(value)'."

        case .validationFailed(let reason):
            return "Error: \(reason)"

        case .unknownSubcommand(let name, _, let suggestion):
            if let suggestion {
                return "Error: Unknown subcommand '\(name)' (did you mean '\(suggestion)'?)."
            }
            return "Error: Unknown subcommand '\(name)'."

        case .missingSubcommand(let available):
            if available.isEmpty {
                return "Error: No subcommand provided."
            }
            return "Error: No subcommand provided. Available subcommands: "
                + available.joined(separator: ", ") + "."
        }
    }

    public static func exitCode(for error: Command.Error) -> Int32 {
        switch error {
        case .helpRequested, .helpRequestedForSubcommand, .versionRequested:
            return 0

        case .exit(let code, _):
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

            return 64

        case .argument:
            return 1
        }
    }
}
