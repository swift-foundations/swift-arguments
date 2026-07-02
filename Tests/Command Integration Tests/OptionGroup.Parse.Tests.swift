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

/// End-to-end parse tests for D16 — `Command.OptionGroup<Root, G>`.
///
/// Validates that an option-group declaration:
/// 1. Splats the fragment schema's nodes into the parent at parse time.
/// 2. Lands values in the fragment's own fields via chained keyPaths.
/// 3. Works at both the flat root level AND inside subcommand-dispatch
///    bodies.
/// 4. Surfaces validation errors uniformly with non-grouped options.
@Suite("Command.OptionGroup — end-to-end parse")
struct CommandOptionGroupParseTests {

    // MARK: - Flat schema (root-level OptionGroup)

    @Test("Flat schema parses --root option through OptionGroup")
    func flatRoot() throws(Command.Error) {
        let parsed = try Command.parse(
            OGFlat.self,
            from: ["--root", "/tmp", "myname"],
            initial: OGFlat()
        )
        #expect(parsed.options.root == "/tmp")
        #expect(parsed.name == "myname")
    }

    @Test("Flat schema retains default when --root is absent")
    func flatDefault() throws(Command.Error) {
        let parsed = try Command.parse(
            OGFlat.self,
            from: ["myname"],
            initial: OGFlat()
        )
        #expect(parsed.options.root == ".")
        #expect(parsed.name == "myname")
    }

    @Test("Flat schema honors --root=value form via OptionGroup")
    func flatEqualsForm() throws(Command.Error) {
        let parsed = try Command.parse(
            OGFlat.self,
            from: ["--root=/usr/src", "x"],
            initial: OGFlat()
        )
        #expect(parsed.options.root == "/usr/src")
    }

    // MARK: - Subcommand dispatch (per-subcommand OptionGroup)

    @Test("Build subcommand parses shared --root via OptionGroup")
    func buildSubcommandRoot() throws(Command.Error) {
        let parsed = try Command.parse(
            OGCLI.self,
            from: ["build", "--root", "/tmp/proj", "MyTarget"],
            initial: .build(.init())
        )
        guard case .build(let build) = parsed else {
            Issue.record("Expected .build case, got \(parsed)")
            return
        }
        #expect(build.options.root == "/tmp/proj")
        #expect(build.target == "MyTarget")
    }

    @Test("Test subcommand parses same shared --root via OptionGroup")
    func testSubcommandRoot() throws(Command.Error) {
        let parsed = try Command.parse(
            OGCLI.self,
            from: ["test", "--root", "/tmp/proj", "MyFilter"],
            initial: .test(.init())
        )
        guard case .test(let test) = parsed else {
            Issue.record("Expected .test case, got \(parsed)")
            return
        }
        #expect(test.options.root == "/tmp/proj")
        #expect(test.filter == "MyFilter")
    }

    @Test("Build subcommand without --root retains shared default")
    func buildSubcommandDefault() throws(Command.Error) {
        let parsed = try Command.parse(
            OGCLI.self,
            from: ["build", "TargetX"],
            initial: .build(.init())
        )
        guard case .build(let build) = parsed else {
            Issue.record("Expected .build case, got \(parsed)")
            return
        }
        #expect(build.options.root == ".")
        #expect(build.target == "TargetX")
    }

    // MARK: - Error paths

    @Test("Unknown option through OptionGroup surfaces .unknownLongOption")
    func unknownOption() {
        do {
            _ = try Command.parse(
                OGFlat.self,
                from: ["--unknown", "x", "myname"],
                initial: OGFlat()
            )
            Issue.record("Expected unknownLongOption, parse succeeded")
        } catch {
            switch error {
            case .unknownLongOption:
                break  // expected

            default:
                Issue.record("Expected unknownLongOption, got \(error)")
            }
        }
    }
}
