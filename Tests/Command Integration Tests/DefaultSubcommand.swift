import Command_Test_Support

struct DefaultList: Command.`Protocol`, Equatable {
}

extension DefaultList {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "list", abstract: "List items.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {}
    }

    mutating func run() async throws(Command.Error) {}
}

struct DefaultClone: Command.`Protocol`, Equatable {
    var url: String

    init(url: String = "") {
        self.url = url
    }
}

extension DefaultClone {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "clone", abstract: "Clone a repository.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.url, name: "url")
        }
    }

    mutating func run() async throws(Command.Error) {}
}

enum RouterWithDefault: Command.`Protocol`, Equatable {
    case list(DefaultList)
    case clone(DefaultClone)
}

extension RouterWithDefault {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "router", abstract: "Router with a default.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Subcommand.Group {
                Command.Subcommand.Case(
                    "list",
                    initial: { DefaultList() },
                    map: Self.list
                ).default
                Command.Subcommand.Case(
                    "clone",
                    initial: { DefaultClone() },
                    map: Self.clone
                )
            }
        }
    }

    mutating func run() async throws(Command.Error) {
        switch self {
        case .list(var sub):
            try await sub.run()
            self = .list(sub)

        case .clone(var sub):
            try await sub.run()
            self = .clone(sub)
        }
    }
}

enum RouterWithoutDefault: Command.`Protocol`, Equatable {
    case list(DefaultList)
    case clone(DefaultClone)
}

extension RouterWithoutDefault {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "router-nodefault", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Subcommand.Group {
                Command.Subcommand.Case(
                    "list",
                    initial: { DefaultList() },
                    map: Self.list
                )
                Command.Subcommand.Case(
                    "clone",
                    initial: { DefaultClone() },
                    map: Self.clone
                )
            }
        }
    }

    mutating func run() async throws(Command.Error) {
        switch self {
        case .list(var sub):
            try await sub.run()
            self = .list(sub)

        case .clone(var sub):
            try await sub.run()
            self = .clone(sub)
        }
    }
}
