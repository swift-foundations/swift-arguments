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

@Suite("Git — help-text emission for subcommand schemas")
struct GitHelpTests {

    @Test("Top-level help lists the SUBCOMMANDS section")
    func helpListsSubcommands() {
        let help = Command.Help<Git>().serialize(Git.schema)
        #expect(help.contains("SUBCOMMANDS:"))
        #expect(help.contains("clone"))
        #expect(help.contains("status"))
        #expect(help.contains("Clone a repository."))
        #expect(help.contains("Show working-tree status."))
    }

    @Test("Top-level USAGE includes <subcommand> placeholder")
    func helpUsageSubcommand() {
        let help = Command.Help<Git>().serialize(Git.schema)
        #expect(help.contains("USAGE: git"))
        #expect(help.contains("<subcommand>"))
    }

    @Test("Top-level OVERVIEW renders the configured abstract")
    func helpOverview() {
        let help = Command.Help<Git>().serialize(Git.schema)
        #expect(help.contains("OVERVIEW: Distributed version control."))
    }

    @Test("Top-level help suggests subcommand help shorthand")
    func helpSuggestsSubHelp() {
        let help = Command.Help<Git>().serialize(Git.schema)
        #expect(help.contains("See 'git help <subcommand>' for detailed help."))
    }

    @Test("Sub-help for 'clone' renders Clone's own ARGUMENTS section")
    func subHelpCloneRendersArguments() {
        do {
            _ = try Command.parse(
                Git.self,
                from: ["clone", "--help"],
                initial: .clone(.init())
            )
            Issue.record("Expected helpRequestedForSubcommand")
        } catch {
            guard case let .helpRequestedForSubcommand(_, rendered) = error else {
                Issue.record("Expected helpRequestedForSubcommand, got \(error)")
                return
            }
            #expect(rendered.contains("USAGE: git clone"))
            #expect(rendered.contains("OVERVIEW: Clone a repository."))
            #expect(rendered.contains("ARGUMENTS:"))
            #expect(rendered.contains("<url>"))
            #expect(rendered.contains("Repository URL."))
        }
    }

    @Test("Sub-help for 'status' renders Status's --short flag")
    func subHelpStatusRendersFlag() {
        do {
            _ = try Command.parse(
                Git.self,
                from: ["status", "--help"],
                initial: .status(.init())
            )
            Issue.record("Expected helpRequestedForSubcommand")
        } catch {
            guard case let .helpRequestedForSubcommand(_, rendered) = error else {
                Issue.record("Expected helpRequestedForSubcommand, got \(error)")
                return
            }
            #expect(rendered.contains("USAGE: git status"))
            #expect(rendered.contains("OVERVIEW: Show working-tree status."))
            #expect(rendered.contains("--short"))
            #expect(rendered.contains("Short format."))
        }
    }
}
