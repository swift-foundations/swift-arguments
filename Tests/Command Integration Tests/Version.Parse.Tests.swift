import Testing

@testable import Command_Test_Support

private struct Versioned: Command.`Protocol`, Equatable {
    var phrase: String = ""
}

extension Versioned {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "versioned",
            abstract: "A command with a version string.",
            version: "1.2.3"
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.phrase, name: "phrase", help: .init(abstract: "A phrase."))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

private struct Unversioned: Command.`Protocol`, Equatable {
    var phrase: String = ""
}

extension Unversioned {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "unversioned",
            abstract: "A command with no version string."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.phrase, name: "phrase", help: .init(abstract: "A phrase."))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

private enum VersionedParent: Command.`Protocol`, Equatable {
    case child(Child)
}

extension VersionedParent {
    struct Child: Command.`Protocol`, Equatable {
        var flag: Bool = false
    }
}

extension VersionedParent.Child {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "child", abstract: "A child subcommand.")
    }
    fileprivate static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag(\.flag, name: .longLiteral("flag"), help: .init(abstract: "A flag."))
        }
    }
    mutating func run() async throws(Command.Error) {}
}

extension VersionedParent {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "parent",
            abstract: "A parent command.",
            version: "4.5.6"
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Subcommand.Group {
                Command.Subcommand.Case("child", initial: { Child() }, map: Self.child)
            }
        }
    }

    mutating func run() async throws(Command.Error) {}
}

extension Command.Configuration {
    @Suite
    struct Version {

        @Test
        func `--version on a versioned command throws .versionRequested`() {
            do throws(Command.Error) {
                _ = try Command.parse(Versioned.self, from: ["--version"], initial: Versioned())
                Issue.record("Expected .versionRequested, parse succeeded")
            } catch {
                switch error {
                case .versionRequested(let version):
                    #expect(version == "1.2.3")

                default:
                    Issue.record("Expected .versionRequested, got \(error)")
                }
            }
        }

        @Test
        func `--version on an unversioned command throws .unknownLongOption`() {
            do throws(Command.Error) {
                _ = try Command.parse(Unversioned.self, from: ["--version"], initial: Unversioned())
                Issue.record("Expected .unknownLongOption, parse succeeded")
            } catch {
                switch error {
                case .unknownLongOption:
                    break

                default:
                    Issue.record("Expected .unknownLongOption, got \(error)")
                }
            }
        }

        @Test
        func `--version on a parent with subcommand group is intercepted before dispatch`() {
            do throws(Command.Error) {
                _ = try Command.parse(
                    VersionedParent.self,
                    from: ["--version"],
                    initial: VersionedParent.child(.init())
                )
                Issue.record("Expected .versionRequested, parse succeeded")
            } catch {
                switch error {
                case .versionRequested(let version):
                    #expect(version == "4.5.6")

                default:
                    Issue.record("Expected .versionRequested, got \(error)")
                }
            }
        }

        @Test
        func `.versionRequested case carries the version string`() {
            let error: Command.Error = .versionRequested(version: "9.8.7")
            switch error {
            case .versionRequested(let version):
                #expect(version == "9.8.7")

            default:
                Issue.record("Expected .versionRequested, got \(error)")
            }
        }
    }
}
