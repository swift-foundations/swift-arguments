import Testing

@testable import Command_Test_Support

extension Command {
    @Suite
    struct `Environment Variable` {

        @Test
        func `Env-var supplies value when option is absent from argv`() throws(Command.Error) {
            let parsed = try Argument.Environment.withOverlay(["ENVCOUNTED_COUNT_TEST": "7"]) {
                () throws(Command.Error) -> EnvCounted in
                try Command.parse(EnvCounted.self, from: ["hello"], initial: EnvCounted())
            }
            #expect(parsed.count == 7)
            #expect(parsed.phrase == "hello")
        }

        @Test
        func `argv value takes precedence over env-var value`() throws(Command.Error) {
            let parsed = try Argument.Environment.withOverlay(["ENVCOUNTED_COUNT_TEST": "7"]) {
                () throws(Command.Error) -> EnvCounted in
                try Command.parse(
                    EnvCounted.self,
                    from: ["--count", "3", "hello"],
                    initial: EnvCounted()
                )
            }
            #expect(parsed.count == 3)
        }

        @Test
        func `Unset env-var leaves the initial default in place`() throws(Command.Error) {

            let parsed = try Command.parse(
                EnvCounted.self,
                from: ["hello"],
                initial: EnvCounted()
            )
            #expect(parsed.count == 2)
        }

        @Test
        func `Env-var value that fails Argument.Codable throws .invalidEnvironmentValue`() {
            do throws(Command.Error) {
                _ = try Argument.Environment.withOverlay(["ENVCOUNTED_COUNT_TEST": "not-an-int"]) {
                    () throws(Command.Error) -> EnvCounted in
                    try Command.parse(EnvCounted.self, from: ["hello"], initial: EnvCounted())
                }
                Issue.record("Expected .invalidEnvironmentValue, parse succeeded")
            } catch {
                switch error {
                case .invalidEnvironmentValue(let name, let envVar, let value):
                    #expect(name == "--count")
                    #expect(envVar == "ENVCOUNTED_COUNT_TEST")
                    #expect(value == "not-an-int")

                default:
                    Issue.record("Expected .invalidEnvironmentValue, got \(error)")
                }
            }
        }

        @Test
        func `Env-var fallback works for options inside an OptionGroup`() throws(Command.Error) {
            let parsed = try Argument.Environment.withOverlay([
                "ENVGROUP_OUTPUT_TEST": "/tmp/result"
            ]) {
                () throws(Command.Error) -> EnvGrouped in
                try Command.parse(EnvGrouped.self, from: ["mytarget"], initial: EnvGrouped())
            }
            #expect(parsed.options.output == "/tmp/result")
            #expect(parsed.target == "mytarget")
        }
    }
}

struct EnvCounted: Command.`Protocol`, Equatable {
    var phrase: String = ""
    var count: Int = 2
}

extension EnvCounted {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "envcounted",
            abstract: "Counts environment-variable fallback."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.phrase, name: "phrase", help: .init(abstract: "A phrase."))
            Command.Option(
                \.count,
                name: .longLiteral("count"),
                help: .init(abstract: "Repeat count."),
                environment: "ENVCOUNTED_COUNT_TEST"
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}

struct EnvGroupFragment: Sendable, Equatable {
    var verbose: Bool = false
    var output: String = "default"
}

extension EnvGroupFragment {
    static let schema: Command.Schema.Definition<Self> = .init {
        Command.Flag(\.verbose, name: .longLiteral("verbose"), help: .init(abstract: "Verbose."))
        Command.Option(
            \.output,
            name: .longLiteral("output"),
            help: .init(abstract: "Output path."),
            environment: "ENVGROUP_OUTPUT_TEST"
        )
    }
}

struct EnvGrouped: Command.`Protocol`, Equatable {
    var options: EnvGroupFragment = .init()
    var target: String = ""
}

extension EnvGrouped {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "envgrouped", abstract: "OptionGroup env-var.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.OptionGroup(\.options, schema: EnvGroupFragment.schema)
            Command.Positional(\.target, name: "target", help: .init(abstract: "Target."))
        }
    }

    mutating func run() async throws(Command.Error) {}
}
