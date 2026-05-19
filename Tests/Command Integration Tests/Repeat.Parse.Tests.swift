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

@Suite("Repeat — end-to-end parse")
struct RepeatParseTests {

    @Test("Parse positional only: ['hello']")
    func positionalOnly() throws(Command.Error) {
        let parsed = try Command.parse(Repeat.self, from: ["hello"], initial: Repeat())
        #expect(parsed == Repeat(phrase: "hello", count: 2, counter: false))
    }

    @Test("Parse option + positional: ['--count', '3', 'hello']")
    func optionAndPositional() throws(Command.Error) {
        let parsed = try Command.parse(
            Repeat.self, from: ["--count", "3", "hello"], initial: Repeat()
        )
        #expect(parsed == Repeat(phrase: "hello", count: 3, counter: false))
    }

    @Test("Parse flag + positional: ['--counter', 'hi']")
    func flagAndPositional() throws(Command.Error) {
        let parsed = try Command.parse(
            Repeat.self, from: ["--counter", "hi"], initial: Repeat()
        )
        #expect(parsed == Repeat(phrase: "hi", count: 2, counter: true))
    }

    @Test("Parse --count=value form")
    func equalsValueForm() throws(Command.Error) {
        let parsed = try Command.parse(
            Repeat.self, from: ["--count=5", "hi"], initial: Repeat()
        )
        #expect(parsed == Repeat(phrase: "hi", count: 5, counter: false))
    }

    @Test("Parse all fields together")
    func allFields() throws(Command.Error) {
        let parsed = try Command.parse(
            Repeat.self,
            from: ["--count", "4", "--counter", "world"],
            initial: Repeat()
        )
        #expect(parsed == Repeat(phrase: "world", count: 4, counter: true))
    }

    // MARK: - Error paths

    @Test("Missing positional throws .missingPositional")
    func missingPositional() {
        do {
            _ = try Command.parse(Repeat.self, from: [], initial: Repeat())
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

    @Test("Invalid Int value throws .invalidValue")
    func invalidIntValue() {
        do {
            _ = try Command.parse(
                Repeat.self, from: ["--count", "not-num", "hi"], initial: Repeat()
            )
            Issue.record("Expected invalidValue, parse succeeded")
        } catch {
            switch error {
            case .invalidValue:
                break  // expected

            default:
                Issue.record("Expected invalidValue, got \(error)")
            }
        }
    }

    @Test("Unknown long option throws .unknownLongOption")
    func unknownLongOption() {
        do {
            _ = try Command.parse(
                Repeat.self, from: ["--unknown", "x", "hi"], initial: Repeat()
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

    @Test("--help triggers .helpRequested")
    func helpRequested() {
        do {
            _ = try Command.parse(Repeat.self, from: ["--help"], initial: Repeat())
            Issue.record("Expected helpRequested, parse succeeded")
        } catch {
            switch error {
            case .helpRequested:
                break  // expected

            default:
                Issue.record("Expected .helpRequested, got \(error)")
            }
        }
    }
}
