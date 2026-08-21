import Command

struct Helper: Command.`Protocol` {
    var phrase: String = ""
}

extension Helper {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "command-runner-helper",
            abstract: "Echoes its phrase; exists to exercise Command.main termination."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(
                \.phrase,
                name: "phrase",
                help: .init(abstract: "The phrase to echo back.")
            )
        }
    }

    mutating func run() async throws(Command.Error) {
        print("HELPER-BEGIN \(phrase) HELPER-END")
    }
}

@main enum Runner {
    static func main() async {
        await Command.main(Helper.self, initial: Helper())
    }
}
