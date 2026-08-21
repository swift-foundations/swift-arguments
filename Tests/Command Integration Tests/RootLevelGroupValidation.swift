import Command_Test_Support

struct RootLevelGroupChild: Command.`Protocol`, Equatable {
}

extension RootLevelGroupChild {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "child", abstract: "A trivial child subcommand.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {}
    }

    mutating func run() async throws(Command.Error) {}
}

struct RootFlagWithGroup: Command.`Protocol`, Equatable {
    var verbose: Bool = false
    var selected: Selected = .child(RootLevelGroupChild())

    enum Selected: Equatable {
        case child(RootLevelGroupChild)
    }
}

extension RootFlagWithGroup {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "rootflagwithgroup",
            abstract: "Root-level flag combined with a Subcommand.Group (F-001 fixture)."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag(
                \.verbose,
                name: .longLiteral("verbose"),
                help: .init(abstract: "Verbose.")
            )
            Command.Subcommand.Group {
                Command.Subcommand.Case(
                    "child",
                    initial: { RootLevelGroupChild() },
                    map: { Self(selected: .child($0)) }
                )
            }
        }
    }

    mutating func run() async throws(Command.Error) {}
}
