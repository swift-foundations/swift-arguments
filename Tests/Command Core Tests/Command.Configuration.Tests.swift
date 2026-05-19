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

import Testing

@testable import Command_Test_Support

@Suite("Command.Configuration")
struct CommandConfigurationTests {

    @Test("Default initializer carries name only")
    func defaultsCarriesNameOnly() {
        let config = Command.Configuration(name: "test")
        #expect(config.name == "test")
        #expect(config.abstract.isEmpty)
        #expect(config.discussion.isEmpty)
        #expect(config.version.isEmpty)
        #expect(config.aliases.isEmpty)
    }

    @Test("Full initializer carries every field")
    func fullInitializer() {
        let config = Command.Configuration(
            name: "git",
            abstract: "Distributed version control.",
            discussion: "Manages source code history.",
            version: "1.0.0",
            aliases: ["g"]
        )
        #expect(config.name == "git")
        #expect(config.abstract == "Distributed version control.")
        #expect(config.discussion == "Manages source code history.")
        #expect(config.version == "1.0.0")
        #expect(config.aliases == ["g"])
    }
}

@Suite("Command.Exit")
struct CommandExitTests {

    @Test(".success has code 0")
    func successCode() {
        #expect(Command.Exit.success.code == 0)
    }

    @Test(".failure has code 1")
    func failureCode() {
        #expect(Command.Exit.failure.code == 1)
    }

    @Test("Custom exit code")
    func customCode() {
        #expect(Command.Exit(code: 42).code == 42)
    }
}
