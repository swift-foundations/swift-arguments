import Command_Test_Support

struct FeatureToggle: Command.`Protocol`, Equatable {
    var feature: Bool

    init(feature: Bool = false) {
        self.feature = feature
    }
}

extension FeatureToggle {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "feature-toggle", abstract: "Inverted-flag demo.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag<Self>.Inverted(
                \.feature,
                base: .literal("feature"),
                inversion: .prefixedNo,
                help: .init(abstract: "Enable or disable the feature.")
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}

struct ServiceToggle: Command.`Protocol`, Equatable {
    var service: Bool

    init(service: Bool = false) {
        self.service = service
    }
}

extension ServiceToggle {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "service-toggle",
            abstract: "Inverted-flag with explicit verbs."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag<Self>.Inverted(
                \.service,
                base: .literal("service"),
                inversion: .prefixedEnableDisable
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}
