import Command_Test_Support

struct GluedShortOptionD: Command.`Protocol`, Equatable {
    var define: String

    init(define: String = "") {
        self.define = define
    }
}

extension GluedShortOptionD {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "glued-d", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option(\.define, name: .shortLiteral("D"))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

struct GluedShortOptionX: Command.`Protocol`, Equatable {
    var jvmFlag: String

    init(jvmFlag: String = "") {
        self.jvmFlag = jvmFlag
    }
}

extension GluedShortOptionX {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "glued-x", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option(\.jvmFlag, name: .shortLiteral("X"))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

struct GluedShortOptionF: Command.`Protocol`, Equatable {
    var flag: String

    init(flag: String = "") {
        self.flag = flag
    }
}

extension GluedShortOptionF {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "glued-f", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option(\.flag, name: .shortLiteral("f"))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

struct NegativeIntPositional: Command.`Protocol`, Equatable {
    var value: Int

    init(value: Int = 0) {
        self.value = value
    }
}

extension NegativeIntPositional {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "neg-int", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.value, name: "value")
        }
    }

    mutating func run() async throws(Command.Error) {}
}

struct NegativeFloatPositional: Command.`Protocol`, Equatable {
    var value: Float

    init(value: Float = 0) {
        self.value = value
    }
}

extension NegativeFloatPositional {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "neg-float", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.value, name: "value")
        }
    }

    mutating func run() async throws(Command.Error) {}
}

struct NegativeNumberWithFiveFlag: Command.`Protocol`, Equatable {
    var fiveFlag: Bool
    var value: Int

    init(fiveFlag: Bool = false, value: Int = 0) {
        self.fiveFlag = fiveFlag
        self.value = value
    }
}

extension NegativeNumberWithFiveFlag {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "flag-five", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag(\.fiveFlag, name: .shortLiteral("5"))
            Command.Positional(\.value, name: "value")
        }
    }

    mutating func run() async throws(Command.Error) {}
}

struct BuildOptionCommand: Command.`Protocol`, Equatable {
    var build: Bool

    init(build: Bool = false) {
        self.build = build
    }
}

extension BuildOptionCommand {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "buildcmd", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag(\.build, name: .longLiteral("build"))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

struct GitSuggestClone: Command.`Protocol`, Equatable {}

extension GitSuggestClone {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "clone", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {}
    }

    mutating func run() async throws(Command.Error) {}
}

struct GitSuggestCommit: Command.`Protocol`, Equatable {}

extension GitSuggestCommit {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "commit", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {}
    }

    mutating func run() async throws(Command.Error) {}
}

struct GitSuggestCheckout: Command.`Protocol`, Equatable {}

extension GitSuggestCheckout {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "checkout", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {}
    }

    mutating func run() async throws(Command.Error) {}
}

enum GitSuggest: Command.`Protocol`, Equatable {
    case clone(GitSuggestClone)
    case commit(GitSuggestCommit)
    case checkout(GitSuggestCheckout)
}

extension GitSuggest {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "git", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Subcommand.Group {
                Command.Subcommand.Case(
                    "clone",
                    initial: { GitSuggestClone() },
                    map: Self.clone
                )
                Command.Subcommand.Case(
                    "commit",
                    initial: { GitSuggestCommit() },
                    map: Self.commit
                )
                Command.Subcommand.Case(
                    "checkout",
                    initial: { GitSuggestCheckout() },
                    map: Self.checkout
                )
            }
        }
    }

    mutating func run() async throws(Command.Error) {}
}
