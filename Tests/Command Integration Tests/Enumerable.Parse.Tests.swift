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

@Suite("Enumerable flag (.Enumerable) parse")
struct EnumerableParseTests {

    @Test("No flag → initial value preserved")
    func noFlag() throws(Command.Error) {
        let parsed = try Command.parse(Calculator.self, from: [], initial: Calculator())
        #expect(parsed.operation == .add)
    }

    @Test("--add selects .add")
    func selectAdd() throws(Command.Error) {
        let parsed = try Command.parse(
            Calculator.self,
            from: ["--add"],
            initial: Calculator(operation: .multiply)
        )
        #expect(parsed.operation == .add)
    }

    @Test("--multiply selects .multiply")
    func selectMultiply() throws(Command.Error) {
        let parsed = try Command.parse(
            Calculator.self,
            from: ["--multiply"],
            initial: Calculator()
        )
        #expect(parsed.operation == .multiply)
    }

    @Test("--divide selects .divide")
    func selectDivide() throws(Command.Error) {
        let parsed = try Command.parse(
            Calculator.self,
            from: ["--divide"],
            initial: Calculator()
        )
        #expect(parsed.operation == .divide)
    }

    @Test("Last occurrence wins (mutual exclusion)")
    func lastOccurrenceWins() throws(Command.Error) {
        let parsed = try Command.parse(
            Calculator.self,
            from: ["--add", "--multiply", "--divide"],
            initial: Calculator()
        )
        #expect(parsed.operation == .divide)
    }
}
