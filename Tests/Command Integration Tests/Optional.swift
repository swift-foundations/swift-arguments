import Command_Test_Support

struct OptionalSchema: Command.`Protocol`, Equatable {
    var label: String?
    var count: Int?

    init(label: String? = nil, count: Int? = nil) {
        self.label = label
        self.count = count
    }
}

extension OptionalSchema {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "opt",
            abstract: "Demonstrates optional-typed schema bindings."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option(
                \.label,
                name: .longLiteral("label"),
                help: .init(abstract: "An optional label.")
            )
            Command.Option(
                \.count,
                name: .longLiteral("count"),
                help: .init(abstract: "An optional count.")
            )
        }
    }

    mutating func run() async throws(Command.Error) {

    }
}
