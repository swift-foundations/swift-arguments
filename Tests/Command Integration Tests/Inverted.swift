// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-arguments open source project
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp and the swift-arguments project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

import Command_Test_Support

/// Fixture for Command.Flag.Inverted with prefixedNo strategy.
struct FeatureToggle: Command.`Protocol`, Equatable {
    var feature: Bool

    init(feature: Bool = false) {
        self.feature = feature
    }

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

/// Fixture for Command.Flag.Inverted with prefixedEnableDisable strategy.
struct ServiceToggle: Command.`Protocol`, Equatable {
    var service: Bool

    init(service: Bool = false) {
        self.service = service
    }

    static var configuration: Command.Configuration {
        Command.Configuration(name: "service-toggle", abstract: "Inverted-flag with explicit verbs.")
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
