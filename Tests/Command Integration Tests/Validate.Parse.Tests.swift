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
struct `Command.Protocol validate Tests` {

    @Test
    func `Default validate() is a no-op for conformers that do not shadow`() throws(Command.Error) {
        let parsed = try Command.parse(
            ValidateNoOp.self,
            from: ["hello"],
            initial: .init()
        )
        #expect(parsed == ValidateNoOp(phrase: "hello"))
    }

    @Test
    func `Shadowed validate() throws on cross-field violation`() {
        do throws(Command.Error) {
            _ = try Command.parse(
                ValidateCrossField.self,
                from: ["--mode", "local", "--remote"],
                initial: .init()
            )
            Issue.record("expected validationFailed throw")
        } catch {
            switch error {
            case .validationFailed(let reason):
                #expect(reason.contains("--mode=local") || reason.contains("--remote"))

            default:
                Issue.record("unexpected error: \(error)")
            }
        }
    }

    @Test
    func `Shadowed validate() passes when cross-field invariant holds`() throws(Command.Error) {
        let parsed = try Command.parse(
            ValidateCrossField.self,
            from: ["--mode", "remote", "--remote"],
            initial: .init()
        )
        #expect(parsed == ValidateCrossField(mode: "remote", remote: true))
    }
}
