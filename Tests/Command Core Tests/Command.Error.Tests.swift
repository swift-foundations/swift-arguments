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

extension Command.Error {
    @Suite("Command.Error")
    struct Test {

    @Test
    func `Cases are distinct`() {
        let position = Argument.Position(argvIndex: 0, byteOffset: 0)
        let helpRequested: Command.Error = .helpRequested
        let unknownLong: Command.Error = .unknownLongOption(
            name: "--x",
            position: position,
            suggestion: nil
        )
        let missingPos: Command.Error = .missingPositional(name: "phrase", position: position)
        let validation: Command.Error = .validationFailed(reason: "bad")
        #expect(helpRequested != unknownLong)
        #expect(missingPos != validation)
    }

    @Test
    func `Equatable conformance`() {
        let position = Argument.Position(argvIndex: 1, byteOffset: 2)
        let a: Command.Error = .invalidValue(name: "--count", value: "x", position: position)
        let b: Command.Error = .invalidValue(name: "--count", value: "x", position: position)
        let c: Command.Error = .invalidValue(name: "--count", value: "y", position: position)
        #expect(a == b)
        #expect(a != c)
    }

    // MARK: - D17 exit case

    @Test
    func `exit case carries code without message`() {
        let error: Command.Error = .exit(code: 2)
        switch error {
        case .exit(let code, let message):
            #expect(code == 2)
            #expect(message == nil)

        default:
            Issue.record("Expected .exit case, got \(error)")
        }
    }

    @Test
    func `exit case carries code and optional message`() {
        let error: Command.Error = .exit(code: 3, message: "Custom diagnostic")
        switch error {
        case .exit(let code, let message):
            #expect(code == 3)
            #expect(message == "Custom diagnostic")

        default:
            Issue.record("Expected .exit case, got \(error)")
        }
    }

    @Test
    func `exit case is throwable and Equatable`() {
        let a: Command.Error = .exit(code: 1, message: "msg")
        let b: Command.Error = .exit(code: 1, message: "msg")
        let c: Command.Error = .exit(code: 2, message: "msg")
        let d: Command.Error = .exit(code: 1, message: "different")
        #expect(a == b)
        #expect(a != c)
        #expect(a != d)
    }

    @Test
    func `exit case usable from run() bodies via typed throws`() {
        // Models a consumer's `run()` body raising an exit:
        // the structural carrier survives the typed-throws path so
        // tests can `catch` and assert without unwrapping any
        // platform-level intrinsic.
        func runBody() throws(Command.Error) {
            throw .exit(code: 64, message: "EX_USAGE")
        }

        do throws(Command.Error) {
            try runBody()
            Issue.record("Expected exit, runBody returned normally")
        } catch {
            switch error {
            case .exit(let code, let message):
                #expect(code == 64)
                #expect(message == "EX_USAGE")

            default:
                Issue.record("Expected .exit case, got \(error)")
            }
        }
    }
    }
}
