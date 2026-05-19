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

/// A minimal Command.`Protocol` fixture used for visitor-only testing.
private struct MinimalCommand: Command.`Protocol`, Equatable {
    var verbose: Bool = false

    static var configuration: Command.Configuration {
        Command.Configuration(name: "minimal", abstract: "Minimal test command.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag(\.verbose, name: .longLiteral("verbose"),
                         help: .init(abstract: "Be verbose."))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

@Suite("Command.Help.Visitor")
struct CommandHelpVisitorTests {

    @Test("Renders USAGE line including the command name")
    func usageLine() {
        let help = Command.Help<MinimalCommand>().serialize(MinimalCommand.schema)
        #expect(help.contains("USAGE: minimal"))
    }

    @Test("Hidden visibility excludes from rendered output")
    func hiddenVisibility() {
        struct HiddenCommand: Command.`Protocol` {
            var verbose: Bool = false
            static var configuration: Command.Configuration { .init(name: "hidden") }
            static var schema: Command.Schema.Definition<Self> {
                Command.Schema.Definition<Self> {
                    Command.Flag(\.verbose, name: .longLiteral("internal"),
                                 visibility: .hidden,
                                 help: .init(abstract: "Internal flag."))
                }
            }
            mutating func run() async throws(Command.Error) {}
        }
        let help = Command.Help<HiddenCommand>().serialize(HiddenCommand.schema)
        // The hidden flag's name should not appear in the help text.
        #expect(!help.contains("--internal"))
        #expect(!help.contains("Internal flag."))
    }
}
