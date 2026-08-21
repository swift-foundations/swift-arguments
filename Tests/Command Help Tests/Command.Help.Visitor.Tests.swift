import Testing

@testable import Command_Test_Support

private struct MinimalCommand: Command.`Protocol`, Equatable {
    var verbose: Bool = false
}

extension MinimalCommand {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "minimal", abstract: "Minimal test command.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag(
                \.verbose,
                name: .longLiteral("verbose"),
                help: .init(abstract: "Be verbose.")
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}

@Suite
struct `Command.Help.Visitor Tests` {

    @Test
    func `Renders USAGE line including the command name`() {
        let help = Command.Help<MinimalCommand>().serialize(MinimalCommand.schema)
        #expect(help.contains("USAGE: minimal"))
    }

    @Test
    func `Hidden visibility excludes from rendered output`() {
        struct HiddenCommand: Command.`Protocol` {
            var verbose: Bool = false
            static var configuration: Command.Configuration { .init(name: "hidden") }
            static var schema: Command.Schema.Definition<Self> {
                Command.Schema.Definition<Self> {
                    Command.Flag(
                        \.verbose,
                        name: .longLiteral("internal"),
                        visibility: .hidden,
                        help: .init(abstract: "Internal flag.")
                    )
                }
            }
            mutating func run() async throws(Command.Error) {}
        }
        let help = Command.Help<HiddenCommand>().serialize(HiddenCommand.schema)

        #expect(!help.contains("--internal"))
        #expect(!help.contains("Internal flag."))
    }
}
