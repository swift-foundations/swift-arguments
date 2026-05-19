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

@Suite("Git — subcommand dispatch")
struct GitParseTests {

    @Test("Parse 'clone <url>' dispatches to .clone case")
    func cloneDispatch() throws(Command.Error) {
        let parsed = try Command.parse(
            Git.self,
            from: ["clone", "https://example.com"],
            initial: .clone(.init())
        )
        #expect(parsed == .clone(Clone(url: "https://example.com")))
    }

    @Test("Parse 'status --short' dispatches to .status case")
    func statusDispatch() throws(Command.Error) {
        let parsed = try Command.parse(
            Git.self,
            from: ["status", "--short"],
            initial: .status(.init())
        )
        #expect(parsed == .status(Status(short: true)))
    }

    @Test("Parse 'status' (no flag) yields default Status")
    func statusDefault() throws(Command.Error) {
        let parsed = try Command.parse(
            Git.self,
            from: ["status"],
            initial: .status(.init())
        )
        #expect(parsed == .status(Status(short: false)))
    }

    @Test("Unknown subcommand throws .unknownSubcommand")
    func unknownSubcommand() {
        do {
            _ = try Command.parse(
                Git.self,
                from: ["unknown"],
                initial: .status(.init())
            )
            Issue.record("Expected unknownSubcommand, parse succeeded")
        } catch {
            switch error {
            case let .unknownSubcommand(name, _, _):
                #expect(name == "unknown")

            default:
                Issue.record("Expected unknownSubcommand, got \(error)")
            }
        }
    }

    @Test("Empty argv with subcommand schema throws .missingSubcommand")
    func missingSubcommand() {
        do {
            _ = try Command.parse(
                Git.self,
                from: [],
                initial: .status(.init())
            )
            Issue.record("Expected missingSubcommand, parse succeeded")
        } catch {
            switch error {
            case let .missingSubcommand(available):
                #expect(available.contains("clone"))
                #expect(available.contains("status"))

            default:
                Issue.record("Expected missingSubcommand, got \(error)")
            }
        }
    }

    @Test("Top-level --help raises .helpRequested")
    func topLevelHelp() {
        do {
            _ = try Command.parse(
                Git.self,
                from: ["--help"],
                initial: .status(.init())
            )
            Issue.record("Expected helpRequested, parse succeeded")
        } catch {
            switch error {
            case .helpRequested:
                break  // expected

            default:
                Issue.record("Expected helpRequested, got \(error)")
            }
        }
    }

    @Test("Sub-help: 'clone --help' raises .helpRequestedForSubcommand")
    func subHelpClone() {
        do {
            _ = try Command.parse(
                Git.self,
                from: ["clone", "--help"],
                initial: .clone(.init())
            )
            Issue.record("Expected helpRequestedForSubcommand, parse succeeded")
        } catch {
            switch error {
            case let .helpRequestedForSubcommand(name, rendered):
                #expect(name == "clone")
                #expect(rendered.contains("git clone"))
                #expect(rendered.contains("Clone a repository."))

            default:
                Issue.record("Expected helpRequestedForSubcommand, got \(error)")
            }
        }
    }

    @Test("Invalid sub-positional reports through .invalidValue")
    func cloneMissingURL() {
        do {
            _ = try Command.parse(
                Git.self,
                from: ["clone"],
                initial: .clone(.init())
            )
            Issue.record("Expected missingPositional, parse succeeded")
        } catch {
            switch error {
            case .missingPositional:
                break  // expected

            default:
                Issue.record("Expected missingPositional, got \(error)")
            }
        }
    }
}
