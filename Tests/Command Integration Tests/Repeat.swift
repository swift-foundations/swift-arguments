import Command_Test_Support

struct Repeat: Command.`Protocol`, Equatable {
    var phrase: String
    var count: Int
    var counter: Bool

    init(phrase: String = "", count: Int = 2, counter: Bool = false) {
        self.phrase = phrase
        self.count = count
        self.counter = counter
    }
}

extension Repeat {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "repeat",
            abstract: "Repeats your input phrase."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(
                \.phrase,
                name: "phrase",
                help: .init(abstract: "The phrase to repeat.")
            )
            Command.Option(
                \.count,
                name: .longLiteral("count"),
                help: .init(abstract: "The number of times to repeat 'phrase'.")
            )
            Command.Flag(
                \.counter,
                name: .longLiteral("counter"),
                help: .init(abstract: "Include a counter with each repetition.")
            )
        }
    }

    mutating func run() async throws(Command.Error) {

    }
}
