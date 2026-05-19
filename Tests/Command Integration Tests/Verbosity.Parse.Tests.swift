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

@Suite("Count-flag (.Count) parse")
struct VerbosityParseTests {

    @Test("No flag occurrence → 0")
    func noOccurrence() throws(Command.Error) {
        let parsed = try Command.parse(Verbosity.self, from: [], initial: Verbosity())
        #expect(parsed.level == 0)
    }

    @Test("Single long occurrence → 1")
    func singleLong() throws(Command.Error) {
        let parsed = try Command.parse(
            Verbosity.self,
            from: ["--verbose"],
            initial: Verbosity()
        )
        #expect(parsed.level == 1)
    }

    @Test("Multiple long occurrences → count")
    func multipleLong() throws(Command.Error) {
        let parsed = try Command.parse(
            Verbosity.self,
            from: ["--verbose", "--verbose", "--verbose"],
            initial: Verbosity()
        )
        #expect(parsed.level == 3)
    }

    @Test("Single short occurrence → 1")
    func singleShort() throws(Command.Error) {
        let parsed = try Command.parse(Verbosity.self, from: ["-v"], initial: Verbosity())
        #expect(parsed.level == 1)
    }

    @Test("Multiple short occurrences as separate flags → count")
    func multipleShortSeparate() throws(Command.Error) {
        let parsed = try Command.parse(
            Verbosity.self,
            from: ["-v", "-v", "-v"],
            initial: Verbosity()
        )
        #expect(parsed.level == 3)
    }

    @Test("Short cluster -vvv → 3")
    func shortCluster() throws(Command.Error) {
        let parsed = try Command.parse(Verbosity.self, from: ["-vvv"], initial: Verbosity())
        #expect(parsed.level == 3)
    }

    @Test("Initial value preserved on no-flag-occurrence")
    func initialValuePreserved() throws(Command.Error) {
        let parsed = try Command.parse(Verbosity.self, from: [], initial: Verbosity(level: 5))
        #expect(parsed.level == 5)
    }
}
