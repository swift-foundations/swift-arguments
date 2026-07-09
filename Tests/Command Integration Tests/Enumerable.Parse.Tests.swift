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
struct `Command.Flag.Enumerable Tests` {

    @Test
    func `No flag → initial value preserved`() throws(Command.Error) {
        let parsed = try Command.parse(Calculator.self, from: [], initial: Calculator())
        #expect(parsed.operation == .add)
    }

    @Test
    func `--add selects .add`() throws(Command.Error) {
        let parsed = try Command.parse(
            Calculator.self,
            from: ["--add"],
            initial: Calculator(operation: .multiply)
        )
        #expect(parsed.operation == .add)
    }

    @Test
    func `--multiply selects .multiply`() throws(Command.Error) {
        let parsed = try Command.parse(
            Calculator.self,
            from: ["--multiply"],
            initial: Calculator()
        )
        #expect(parsed.operation == .multiply)
    }

    @Test
    func `--divide selects .divide`() throws(Command.Error) {
        let parsed = try Command.parse(
            Calculator.self,
            from: ["--divide"],
            initial: Calculator()
        )
        #expect(parsed.operation == .divide)
    }

    @Test
    func `Last occurrence wins (mutual exclusion)`() throws(Command.Error) {
        let parsed = try Command.parse(
            Calculator.self,
            from: ["--add", "--multiply", "--divide"],
            initial: Calculator()
        )
        #expect(parsed.operation == .divide)
    }
}
