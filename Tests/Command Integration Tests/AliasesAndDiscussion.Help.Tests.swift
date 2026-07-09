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

// MARK: - Fixtures

/// A command with discussion and aliases declared.
private struct DocumentedCommand: Command.`Protocol`, Equatable {
    var input: String = ""
}

extension DocumentedCommand {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "documented",
            abstract: "A well-documented command.",
            discussion: "This command demonstrates the discussion section.\nMultiple lines are rendered indented.",
            aliases: ["doc", "docu"]
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.input, name: "input", help: .init(abstract: "Input value."))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

/// A command with neither discussion nor aliases (negative control).
private struct PlainCommand: Command.`Protocol`, Equatable {
    var input: String = ""
}

extension PlainCommand {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "plain",
            abstract: "A plain command."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.input, name: "input", help: .init(abstract: "Input value."))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

@Suite("Aliases and Discussion in help text")
struct AliasesAndDiscussionHelpTests {

    // Why these tests exist:
    //
    // Before B1 closure:
    //
    //   - `Command.Configuration.aliases` (declared at
    //     Command.Configuration.swift:49) was inert at the root level —
    //     no code path rendered it. The principal direction was to match
    //     Apple's swift-argument-parser by surfacing it in the help
    //     output (rather than deleting the field).
    //
    //   - `Command.Configuration.discussion` (declared at
    //     Command.Configuration.swift:43) was captured but never
    //     emitted — `Command.Help.Visitor.render()` produced
    //     OVERVIEW/ARGUMENTS/OPTIONS/SUBCOMMANDS only, with no
    //     DISCUSSION section.
    //
    // The fixes add ALIASES and DISCUSSION sections to the help-text
    // emission whenever the configuration declares them, leaving the
    // existing snapshot output unchanged for commands that do not use
    // these fields.

    @Test
    func `Help renders ALIASES section when aliases are non-empty`() {
        let help = Command.Help<DocumentedCommand>().serialize(DocumentedCommand.schema)
        #expect(help.contains("ALIASES: doc, docu"))
    }

    @Test
    func `Help renders DISCUSSION section when discussion is non-empty`() {
        let help = Command.Help<DocumentedCommand>().serialize(DocumentedCommand.schema)
        #expect(help.contains("DISCUSSION:"))
        #expect(help.contains("  This command demonstrates the discussion section."))
        #expect(help.contains("  Multiple lines are rendered indented."))
    }

    @Test
    func `Help omits ALIASES section when aliases are empty`() {
        let help = Command.Help<PlainCommand>().serialize(PlainCommand.schema)
        #expect(!help.contains("ALIASES:"))
    }

    @Test
    func `Help omits DISCUSSION section when discussion is empty`() {
        let help = Command.Help<PlainCommand>().serialize(PlainCommand.schema)
        #expect(!help.contains("DISCUSSION:"))
    }

    @Test
    func `Aliases and discussion appear in expected order`() {
        let help = Command.Help<DocumentedCommand>().serialize(DocumentedCommand.schema)
        // Order check via prefix-scan: walk the string once and record
        // first occurrence index of each section header.
        let sections = ["USAGE:", "OVERVIEW:", "ALIASES:", "DISCUSSION:", "ARGUMENTS:"]
        var positions: [String: Int] = [:]
        for section in sections {
            // Linear scan to find the first occurrence — avoids
            // dependence on Foundation's `range(of:)` API.
            let helpCount = help.count
            let needleCount = section.count
            guard helpCount >= needleCount else { continue }
            for offset in 0...(helpCount - needleCount) {
                let startIndex = help.index(help.startIndex, offsetBy: offset)
                let endIndex = help.index(startIndex, offsetBy: needleCount)
                if String(help[startIndex..<endIndex]) == section {
                    positions[section] = offset
                    break
                }
            }
        }
        // USAGE → OVERVIEW → ALIASES → DISCUSSION → ARGUMENTS
        guard let usagePos = positions["USAGE:"],
            let overviewPos = positions["OVERVIEW:"],
            let aliasesPos = positions["ALIASES:"],
            let discussionPos = positions["DISCUSSION:"],
            let argumentsPos = positions["ARGUMENTS:"]
        else {
            Issue.record("Missing section header in help text: \(help)")
            return
        }
        #expect(usagePos < overviewPos)
        #expect(overviewPos < aliasesPos)
        #expect(aliasesPos < discussionPos)
        #expect(discussionPos < argumentsPos)
    }
}
