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

/// Help-text emission tests for D16 — `Command.OptionGroup<Root, G>`.
///
/// Validates that an option-group declaration inlines the fragment
/// schema's options into the parent command's `--help` output, matching
/// the rendered shape that a flat (non-grouped) schema would produce.
@Suite("Command.OptionGroup — help-text emission")
struct CommandOptionGroupHelpTests {

    @Test
    func `Flat OptionGroup renders --root in OPTIONS section`() {
        let help = Command.Help<OGFlat>().serialize(OGFlat.schema)
        #expect(help.contains("--root"))
        #expect(help.contains("Repository root directory."))
    }

    @Test
    func `Flat OptionGroup keeps positional in ARGUMENTS section`() {
        let help = Command.Help<OGFlat>().serialize(OGFlat.schema)
        #expect(help.contains("ARGUMENTS:"))
        #expect(help.contains("<name>"))
        #expect(help.contains("A name."))
    }

    @Test
    func `Subcommand 'build' --help inlines shared --root row`() {
        do throws(Command.Error) {
            _ = try Command.parse(
                OGCLI.self,
                from: ["build", "--help"],
                initial: .build(.init())
            )
            Issue.record("Expected helpRequestedForSubcommand, parse succeeded")
        } catch {
            switch error {
            case .helpRequestedForSubcommand(let name, let rendered):
                #expect(name == "build")
                #expect(rendered.contains("--root"))
                #expect(rendered.contains("Repository root directory."))
                #expect(rendered.contains("USAGE: og build"))

            default:
                Issue.record("Expected helpRequestedForSubcommand, got \(error)")
            }
        }
    }

    @Test
    func `Subcommand 'test' --help also inlines shared --root row`() {
        do throws(Command.Error) {
            _ = try Command.parse(
                OGCLI.self,
                from: ["test", "--help"],
                initial: .test(.init())
            )
            Issue.record("Expected helpRequestedForSubcommand, parse succeeded")
        } catch {
            switch error {
            case .helpRequestedForSubcommand(let name, let rendered):
                #expect(name == "test")
                #expect(rendered.contains("--root"))
                #expect(rendered.contains("Repository root directory."))
                #expect(rendered.contains("USAGE: og test"))

            default:
                Issue.record("Expected helpRequestedForSubcommand, got \(error)")
            }
        }
    }

    @Test
    func `Hidden OptionGroup omits its options from help`() {
        // Inline schema with a hidden group — assert the group's rows
        // do NOT appear in --help.
        struct HiddenOG: Command.`Protocol`, Equatable {
            var options: SharedRootOptions = .init()
            var name: String = ""

            static var configuration: Command.Configuration {
                Command.Configuration(name: "hog", abstract: "Hidden group demo.")
            }

            static var schema: Command.Schema.Definition<Self> {
                Command.Schema.Definition<Self> {
                    Command.OptionGroup(
                        \.options,
                        schema: SharedRootOptions.schema,
                        visibility: .hidden
                    )
                    Command.Positional(\.name, name: "name")
                }
            }

            mutating func run() async throws(Command.Error) {}
        }

        let help = Command.Help<HiddenOG>().serialize(HiddenOG.schema)
        #expect(!help.contains("--root"))
        #expect(!help.contains("Repository root directory."))
        // Positional still rendered.
        #expect(help.contains("<name>"))
    }
}
