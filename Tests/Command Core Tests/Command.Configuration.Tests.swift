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

extension Command.Configuration {
    @Suite("Command.Configuration")
    struct Test {

        @Test
        func `Default initializer carries name only`() {
            let config = Command.Configuration(name: "test")
            #expect(config.name == "test")
            #expect(config.abstract.isEmpty)
            #expect(config.discussion.isEmpty)
            #expect(config.version.isEmpty)
            #expect(config.aliases.isEmpty)
        }

        @Test
        func `Full initializer carries every field`() {
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
}

extension Command.Exit {
    @Suite("Command.Exit")
    struct Test {

        @Test
        func `.success has code 0`() {
            #expect(Command.Exit.success.code == 0)
        }

        @Test
        func `.failure has code 1`() {
            #expect(Command.Exit.failure.code == 1)
        }

        @Test
        func `Custom exit code`() {
            #expect(Command.Exit(code: 42).code == 42)
        }
    }
}
