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
struct `Command.Flag.Count Tests` {

    @Test
    func `No flag occurrence → 0`() throws(Command.Error) {
        let parsed = try Command.parse(Verbosity.self, from: [], initial: Verbosity())
        #expect(parsed.level == 0)
    }

    @Test
    func `Single long occurrence → 1`() throws(Command.Error) {
        let parsed = try Command.parse(
            Verbosity.self,
            from: ["--verbose"],
            initial: Verbosity()
        )
        #expect(parsed.level == 1)
    }

    @Test
    func `Multiple long occurrences → count`() throws(Command.Error) {
        let parsed = try Command.parse(
            Verbosity.self,
            from: ["--verbose", "--verbose", "--verbose"],
            initial: Verbosity()
        )
        #expect(parsed.level == 3)
    }

    @Test
    func `Single short occurrence → 1`() throws(Command.Error) {
        let parsed = try Command.parse(Verbosity.self, from: ["-v"], initial: Verbosity())
        #expect(parsed.level == 1)
    }

    @Test
    func `Multiple short occurrences as separate flags → count`() throws(Command.Error) {
        let parsed = try Command.parse(
            Verbosity.self,
            from: ["-v", "-v", "-v"],
            initial: Verbosity()
        )
        #expect(parsed.level == 3)
    }

    @Test
    func `Short cluster -vvv → 3`() throws(Command.Error) {
        let parsed = try Command.parse(Verbosity.self, from: ["-vvv"], initial: Verbosity())
        #expect(parsed.level == 3)
    }

    @Test
    func `Initial value preserved on no-flag-occurrence`() throws(Command.Error) {
        let parsed = try Command.parse(Verbosity.self, from: [], initial: Verbosity(level: 5))
        #expect(parsed.level == 5)
    }
}
