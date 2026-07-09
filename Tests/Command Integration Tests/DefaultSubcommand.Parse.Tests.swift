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

@Suite("Command.Subcommand.Case — .default modifier")
struct DefaultSubcommandParseTests {

    @Test
    func `Empty argv dispatches the default subcommand`() throws(Command.Error) {
        let parsed = try Command.parse(
            RouterWithDefault.self,
            from: [],
            initial: .list(.init())
        )
        #expect(parsed == .list(DefaultList()))
    }

    @Test
    func `Explicit subcommand overrides the default`() throws(Command.Error) {
        let parsed = try Command.parse(
            RouterWithDefault.self,
            from: ["clone", "https://example.com"],
            initial: .list(.init())
        )
        #expect(parsed == .clone(DefaultClone(url: "https://example.com")))
    }

    @Test
    func `Empty argv without a default throws .missingSubcommand`() {
        do throws(Command.Error) {
            _ = try Command.parse(
                RouterWithoutDefault.self,
                from: [],
                initial: .list(.init())
            )
            Issue.record("expected missingSubcommand throw")
        } catch {
            switch error {
            case .missingSubcommand(let available):
                #expect(available.contains("list"))
                #expect(available.contains("clone"))

            default:
                Issue.record("unexpected error: \(error)")
            }
        }
    }
}
