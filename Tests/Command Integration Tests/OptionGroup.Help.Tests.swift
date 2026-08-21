import Testing

@testable import Command_Test_Support

@Suite
struct `Command.OptionGroup Help Tests` {

    @Test
    func `Flat OptionGroup renders --root in OPTIONS section`() {
        let help = Command.Help<OGFlat>().serialize(OGFlat.schema)
        #expect(help.contains("--root"))
        #expect(help.contains("Repository root directory."))
    }

    @Test
    func `Flat OptionGroup keeps positional in ARGUMENTS section`() {
        let help = Command.Help<OGFlat>().serialize(OGFlat.schema)
        #expect(help.contains("ARGUMENTS:"))
        #expect(help.contains("<name>"))
        #expect(help.contains("A name."))
    }

    @Test
    func `Subcommand 'build' --help inlines shared --root row`() {
        do throws(Command.Error) {
            _ = try Command.parse(
                OGCLI.self,
                from: ["build", "--help"],
                initial: .build(.init())
            )
            Issue.record("Expected helpRequestedForSubcommand, parse succeeded")
        } catch {
            switch error {
            case .helpRequestedForSubcommand(let name, let rendered):
                #expect(name == "build")
                #expect(rendered.contains("--root"))
                #expect(rendered.contains("Repository root directory."))
                #expect(rendered.contains("USAGE: og build"))

            default:
                Issue.record("Expected helpRequestedForSubcommand, got \(error)")
            }
        }
    }

    @Test
    func `Subcommand 'test' --help also inlines shared --root row`() {
        do throws(Command.Error) {
            _ = try Command.parse(
                OGCLI.self,
                from: ["test", "--help"],
                initial: .test(.init())
            )
            Issue.record("Expected helpRequestedForSubcommand, parse succeeded")
        } catch {
            switch error {
            case .helpRequestedForSubcommand(let name, let rendered):
                #expect(name == "test")
                #expect(rendered.contains("--root"))
                #expect(rendered.contains("Repository root directory."))
                #expect(rendered.contains("USAGE: og test"))

            default:
                Issue.record("Expected helpRequestedForSubcommand, got \(error)")
            }
        }
    }

    @Test
    func `Hidden OptionGroup omits its options from help`() {

        struct HiddenOG: Command.`Protocol`, Equatable {
            var options: SharedRootOptions = .init()
            var name: String = ""

            static var configuration: Command.Configuration {
                Command.Configuration(name: "hog", abstract: "Hidden group demo.")
            }

            static var schema: Command.Schema.Definition<Self> {
                Command.Schema.Definition<Self> {
                    Command.OptionGroup(
                        \.options,
                        schema: SharedRootOptions.schema,
                        visibility: .hidden
                    )
                    Command.Positional(\.name, name: "name")
                }
            }

            mutating func run() async throws(Command.Error) {}
        }

        let help = Command.Help<HiddenOG>().serialize(HiddenOG.schema)
        #expect(!help.contains("--root"))
        #expect(!help.contains("Repository root directory."))

        #expect(help.contains("<name>"))
    }
}
