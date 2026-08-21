import Command_Test_Support

struct TransformedHost: Sendable, Equatable {
    let scheme: String
    let host: String
}

extension TransformedHost {

    static func parse(_ string: String) -> Self? {
        var schemeChars: [Character] = []
        var hostChars: [Character] = []
        var seenColon = false
        var seenFirstSlash = false
        var seenSecondSlash = false
        for character in string {
            if !seenColon {
                if character == ":" {
                    seenColon = true
                } else {
                    schemeChars.append(character)
                }
                continue
            }
            if !seenFirstSlash {
                guard character == "/" else { return nil }
                seenFirstSlash = true
                continue
            }
            if !seenSecondSlash {
                guard character == "/" else { return nil }
                seenSecondSlash = true
                continue
            }
            hostChars.append(character)
        }
        guard seenSecondSlash else { return nil }
        guard !schemeChars.isEmpty, !hostChars.isEmpty else { return nil }
        return Self(
            scheme: String(schemeChars),
            host: String(hostChars)
        )
    }
}

struct TransformedPositional: Command.`Protocol`, Equatable {
    var endpoint: TransformedHost

    init(endpoint: TransformedHost = TransformedHost(scheme: "", host: "")) {
        self.endpoint = endpoint
    }
}

extension TransformedPositional {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "transformed-positional",
            abstract: "Bind a positional through a transform closure."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional<Self, TransformedHost>(
                \.endpoint,
                name: "endpoint",
                help: .init(abstract: "The endpoint in scheme://host form."),
                transform: { string throws(Command.Error) in
                    guard let parsed = TransformedHost.parse(string) else {
                        throw .invalidValue(
                            name: "endpoint",
                            value: string,
                            position: .init(argvIndex: 0, byteOffset: 0)
                        )
                    }
                    return parsed
                }
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}

struct TransformedOption: Command.`Protocol`, Equatable {
    var endpoint: TransformedHost

    init(endpoint: TransformedHost = TransformedHost(scheme: "", host: "")) {
        self.endpoint = endpoint
    }
}

extension TransformedOption {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "transformed-option",
            abstract: "Bind an option through a transform closure."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option<Self, TransformedHost>(
                \.endpoint,
                name: .longLiteral("endpoint"),
                help: .init(abstract: "The endpoint in scheme://host form."),
                transform: { string throws(Command.Error) in
                    guard let parsed = TransformedHost.parse(string) else {
                        throw .invalidValue(
                            name: "--endpoint",
                            value: string,
                            position: .init(argvIndex: 0, byteOffset: 0)
                        )
                    }
                    return parsed
                }
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}

struct TransformedPositionalMany: Command.`Protocol`, Equatable {
    var endpoints: [TransformedHost]

    init(endpoints: [TransformedHost] = []) {
        self.endpoints = endpoints
    }
}

extension TransformedPositionalMany {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "transformed-positional-many",
            abstract: "Bind a rest-positional through a transform closure."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional<Self, TransformedHost>.Many(
                \.endpoints,
                name: "endpoints",
                help: .init(abstract: "Endpoint values in scheme://host form."),
                transform: { string throws(Command.Error) in
                    guard let parsed = TransformedHost.parse(string) else {
                        throw .invalidValue(
                            name: "endpoints",
                            value: string,
                            position: .init(argvIndex: 0, byteOffset: 0)
                        )
                    }
                    return parsed
                }
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}

struct TransformedOptionMany: Command.`Protocol`, Equatable {
    var endpoints: [TransformedHost]

    init(endpoints: [TransformedHost] = []) {
        self.endpoints = endpoints
    }
}

extension TransformedOptionMany {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "transformed-option-many",
            abstract: "Bind a repeatable option through a transform closure."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option<Self, TransformedHost>.Many(
                \.endpoints,
                name: .longLiteral("endpoint"),
                help: .init(abstract: "Endpoint values in scheme://host form."),
                transform: { string throws(Command.Error) in
                    guard let parsed = TransformedHost.parse(string) else {
                        throw .invalidValue(
                            name: "--endpoint",
                            value: string,
                            position: .init(argvIndex: 0, byteOffset: 0)
                        )
                    }
                    return parsed
                }
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}
