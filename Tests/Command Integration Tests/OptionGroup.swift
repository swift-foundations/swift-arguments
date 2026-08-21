import Command_Test_Support

struct SharedRootOptions: Sendable, Equatable {

    var root: String = "."
}

extension SharedRootOptions {

    static let schema: Command.Schema.Definition<Self> = .init {
        Command.Option(
            \.root,
            name: .longLiteral("root"),
            help: .init(abstract: "Repository root directory.")
        )
    }
}

struct OGBuild: Command.`Protocol`, Equatable {
    var options: SharedRootOptions = .init()
    var target: String = ""
}

extension OGBuild {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "build", abstract: "Build a target.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.OptionGroup(\.options, schema: SharedRootOptions.schema)
            Command.Positional(\.target, name: "target", help: .init(abstract: "Target name."))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

struct OGTest: Command.`Protocol`, Equatable {
    var options: SharedRootOptions = .init()
    var filter: String = ""
}

extension OGTest {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "test", abstract: "Run tests.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.OptionGroup(\.options, schema: SharedRootOptions.schema)
            Command.Positional(\.filter, name: "filter", help: .init(abstract: "Test filter."))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

enum OGCLI: Command.`Protocol`, Equatable {
    case build(OGBuild)
    case test(OGTest)
}

extension OGCLI {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "og",
            abstract: "Demonstrates option groups across subcommands."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Subcommand.Group {
                Command.Subcommand.Case(
                    "build",
                    initial: { OGBuild() },
                    map: Self.build
                )
                Command.Subcommand.Case(
                    "test",
                    initial: { OGTest() },
                    map: Self.test
                )
            }
        }
    }

    mutating func run() async throws(Command.Error) {}
}

struct OGFlat: Command.`Protocol`, Equatable {
    var options: SharedRootOptions = .init()
    var name: String = ""
}

extension OGFlat {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "ogflat", abstract: "Flat schema with one OptionGroup.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.OptionGroup(\.options, schema: SharedRootOptions.schema)
            Command.Positional(\.name, name: "name", help: .init(abstract: "A name."))
        }
    }

    mutating func run() async throws(Command.Error) {}
}
