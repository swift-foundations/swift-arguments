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

@Suite
struct Test {

    @Test
    func `Parse 'clone <url>' dispatches to .clone case`() throws(Command.Error) {
        let parsed = try Command.parse(
            Git.self,
            from: ["clone", "https://example.com"],
            initial: .clone(.init())
        )
        #expect(parsed == .clone(Clone(url: "https://example.com")))
    }

    @Test
    func `Parse 'status --short' dispatches to .status case`() throws(Command.Error) {
        let parsed = try Command.parse(
            Git.self,
            from: ["status", "--short"],
            initial: .status(.init())
        )
        #expect(parsed == .status(Status(short: true)))
    }

    @Test
    func `Parse 'status' (no flag) yields default Status`() throws(Command.Error) {
        let parsed = try Command.parse(
            Git.self,
            from: ["status"],
            initial: .status(.init())
        )
        #expect(parsed == .status(Status(short: false)))
    }

    @Test
    func `Unknown subcommand throws .unknownSubcommand`() {
        do throws(Command.Error) {
            _ = try Command.parse(
                Git.self,
                from: ["unknown"],
                initial: .status(.init())
            )
            Issue.record("Expected unknownSubcommand, parse succeeded")
        } catch {
            switch error {
            case .unknownSubcommand(let name, _, _):
                #expect(name == "unknown")

            default:
                Issue.record("Expected unknownSubcommand, got \(error)")
            }
        }
    }

    @Test
    func `Empty argv with subcommand schema throws .missingSubcommand`() {
        do throws(Command.Error) {
            _ = try Command.parse(
                Git.self,
                from: [],
                initial: .status(.init())
            )
            Issue.record("Expected missingSubcommand, parse succeeded")
        } catch {
            switch error {
            case .missingSubcommand(let available):
                #expect(available.contains("clone"))
                #expect(available.contains("status"))

            default:
                Issue.record("Expected missingSubcommand, got \(error)")
            }
        }
    }

    @Test
    func `Top-level --help raises .helpRequested`() {
        do throws(Command.Error) {
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

    @Test
    func `Sub-help: 'clone --help' raises .helpRequestedForSubcommand`() {
        do throws(Command.Error) {
            _ = try Command.parse(
                Git.self,
                from: ["clone", "--help"],
                initial: .clone(.init())
            )
            Issue.record("Expected helpRequestedForSubcommand, parse succeeded")
        } catch {
            switch error {
            case .helpRequestedForSubcommand(let name, let rendered):
                #expect(name == "clone")
                #expect(rendered.contains("git clone"))
                #expect(rendered.contains("Clone a repository."))

            default:
                Issue.record("Expected helpRequestedForSubcommand, got \(error)")
            }
        }
    }

    @Test
    func `Invalid sub-positional reports through .invalidValue`() {
        do throws(Command.Error) {
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
