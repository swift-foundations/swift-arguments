import Testing

@testable import Command_Test_Support

private struct AutoDefaultFixture: Command.`Protocol`, Equatable {
    var phrase: String
    var count: Int
    var counter: Bool

    init(phrase: String = "", count: Int = 7, counter: Bool = false) {
        self.phrase = phrase
        self.count = count
        self.counter = counter
    }
}

extension AutoDefaultFixture {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "auto", abstract: "Auto-default fixture.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.phrase, name: "phrase")
            Command.Option(\.count, name: .longLiteral("count"))
            Command.Flag(\.counter, name: .longLiteral("counter"))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

private struct OptionalIntFixture: Command.`Protocol`, Equatable {
    var port: Int?

    init(port: Int? = nil) {
        self.port = port
    }
}

extension OptionalIntFixture {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "opt", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option(\.port, name: .longLiteral("port"))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

@Suite
struct `Command.Help AutoDefault Tests` {

    @Test
    func `Int default auto-derived for Option`() {
        var buffer = ""
        Command.Help<AutoDefaultFixture>().serialize(
            AutoDefaultFixture.schema,
            into: &buffer,
            initial: AutoDefaultFixture()
        )
        #expect(buffer.contains("--count <count>"))
        #expect(buffer.contains("(default: 7)"))
    }

    @Test
    func `String default auto-derived for Positional`() {
        var buffer = ""
        Command.Help<AutoDefaultFixture>().serialize(
            AutoDefaultFixture.schema,
            into: &buffer,
            initial: AutoDefaultFixture(phrase: "hello")
        )

        #expect(buffer.contains("<phrase>"))
        #expect(buffer.contains("(default: hello)"))
    }

    @Test
    func `Bool flag default NOT rendered`() {
        var buffer = ""
        Command.Help<AutoDefaultFixture>().serialize(
            AutoDefaultFixture.schema,
            into: &buffer,
            initial: AutoDefaultFixture(counter: true)
        )

        #expect(buffer.contains("--counter"))
        #expect(!buffer.contains("(default: true)"))
        #expect(!buffer.contains("(default: false)"))
    }

    @Test
    func `Optional<Int> nil-default rendered with no default line`() {
        var buffer = ""
        Command.Help<OptionalIntFixture>().serialize(
            OptionalIntFixture.schema,
            into: &buffer,
            initial: OptionalIntFixture(port: nil)
        )
        #expect(buffer.contains("--port"))
        #expect(!buffer.contains("(default:"))
    }

    @Test
    func `Optional<Int> some(8080) renders default 8080`() {
        var buffer = ""
        Command.Help<OptionalIntFixture>().serialize(
            OptionalIntFixture.schema,
            into: &buffer,
            initial: OptionalIntFixture(port: 8080)
        )
        #expect(buffer.contains("--port"))
        #expect(buffer.contains("(default: 8080)"))
    }

    @Test
    func `No-initial overload preserves v1.0.15 behavior — no auto-default`() {
        var buffer = ""
        Command.Help<AutoDefaultFixture>().serialize(
            AutoDefaultFixture.schema,
            into: &buffer
        )

        #expect(buffer.contains("--count <count>"))
        #expect(!buffer.contains("(default: 7)"))
    }
}
