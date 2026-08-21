import Command_Test_Support

struct Clone: Command.`Protocol`, Equatable {
    var url: String

    init(url: String = "") {
        self.url = url
    }
}

extension Clone {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "clone",
            abstract: "Clone a repository."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(
                \.url,
                name: "url",
                help: .init(abstract: "Repository URL.")
            )
        }
    }

    mutating func run() async throws(Command.Error) {

    }
}

struct Status: Command.`Protocol`, Equatable {
    var short: Bool

    init(short: Bool = false) {
        self.short = short
    }
}

extension Status {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "status",
            abstract: "Show working-tree status."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag(
                \.short,
                name: .longLiteral("short"),
                help: .init(abstract: "Short format.")
            )
        }
    }

    mutating func run() async throws(Command.Error) {

    }
}

enum Git: Command.`Protocol`, Equatable {
    case clone(Clone)
    case status(Status)
}

extension Git {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "git",
            abstract: "Distributed version control."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Subcommand.Group {
                Command.Subcommand.Case(
                    "clone",
                    help: .init(abstract: "Clone a repository."),
                    initial: { Clone() },
                    map: Self.clone
                )
                Command.Subcommand.Case(
                    "status",
                    help: .init(abstract: "Show working-tree status."),
                    initial: { Status() },
                    map: Self.status
                )
            }
        }
    }

    mutating func run() async throws(Command.Error) {
        switch self {
        case .clone(var c):
            try await c.run()
            self = .clone(c)

        case .status(var s):
            try await s.run()
            self = .status(s)
        }
    }
}
