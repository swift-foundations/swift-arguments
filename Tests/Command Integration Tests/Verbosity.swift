import Command_Test_Support

struct Verbosity: Command.`Protocol`, Equatable {
    var level: Int

    init(level: Int = 0) {
        self.level = level
    }
}

extension Verbosity {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "verbosity", abstract: "Count-flag verbosity demo.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag<Self>.Count(
                \.level,
                name: .bothLiteral(short: "v", long: "verbose"),
                help: .init(abstract: "Increase verbosity (repeatable).")
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}
