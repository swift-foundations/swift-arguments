public import Argument_Primitives

extension Command {

    public enum Error: Swift.Error, Sendable, Hashable, Equatable {

        case argument(Argument.Error)

        case tokenizer(reason: String, argvIndex: Swift.Int)

        case unknownLongOption(name: String, position: Argument.Position, suggestion: String?)

        case unknownShortOption(name: Character, position: Argument.Position)

        case missingOptionValue(name: String, position: Argument.Position)

        case invalidValue(name: String, value: String, position: Argument.Position)

        case invalidEnvironmentValue(
            name: String,
            environment: Argument.Environment.Variable.Name,
            value: String
        )

        case missingPositional(name: String, position: Argument.Position)

        case unexpectedPositional(value: String, position: Argument.Position)

        case validationFailed(reason: String)

        case helpRequested

        case versionRequested(version: String)

        case unknownSubcommand(name: String, position: Argument.Position, suggestion: String?)

        case helpRequestedForSubcommand(name: String, rendered: String)

        case missingSubcommand(available: [String])

        case exit(code: Int32, message: String? = nil)
    }
}
