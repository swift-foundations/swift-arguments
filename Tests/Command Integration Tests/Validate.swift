import Command_Test_Support

struct ValidateNoOp: Command.`Protocol`, Equatable {
    var phrase: String

    init(phrase: String = "") {
        self.phrase = phrase
    }
}

extension ValidateNoOp {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "validate-no-op", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.phrase, name: "phrase")
        }
    }

    mutating func run() async throws(Command.Error) {

    }
}

struct ValidateCrossField: Command.`Protocol`, Equatable {
    var mode: String
    var remote: Bool

    init(mode: String = "local", remote: Bool = false) {
        self.mode = mode
        self.remote = remote
    }
}

extension ValidateCrossField {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "validate-cross", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option(\.mode, name: .longLiteral("mode"))
            Command.Flag(\.remote, name: .longLiteral("remote"))
        }
    }

    mutating func validate() throws(Command.Error) {
        if mode == "local" && remote {
            throw .validationFailed(
                reason: "Cannot combine --mode=local with --remote."
            )
        }
    }

    mutating func run() async throws(Command.Error) {

    }
}
