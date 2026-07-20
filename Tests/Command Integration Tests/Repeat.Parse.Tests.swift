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

extension Repeat {
    @Suite
    struct Parse {

        @Test
        func `Parse positional only: ['hello']`() throws(Command.Error) {
            let parsed = try Command.parse(Repeat.self, from: ["hello"], initial: Repeat())
            #expect(parsed == Repeat(phrase: "hello", count: 2, counter: false))
        }

        @Test
        func `Parse option + positional: ['--count', '3', 'hello']`() throws(Command.Error) {
            let parsed = try Command.parse(
                Repeat.self,
                from: ["--count", "3", "hello"],
                initial: Repeat()
            )
            #expect(parsed == Repeat(phrase: "hello", count: 3, counter: false))
        }

        @Test
        func `Parse flag + positional: ['--counter', 'hi']`() throws(Command.Error) {
            let parsed = try Command.parse(
                Repeat.self,
                from: ["--counter", "hi"],
                initial: Repeat()
            )
            #expect(parsed == Repeat(phrase: "hi", count: 2, counter: true))
        }

        @Test
        func `Parse --count=value form`() throws(Command.Error) {
            let parsed = try Command.parse(
                Repeat.self,
                from: ["--count=5", "hi"],
                initial: Repeat()
            )
            #expect(parsed == Repeat(phrase: "hi", count: 5, counter: false))
        }

        @Test
        func `Parse all fields together`() throws(Command.Error) {
            let parsed = try Command.parse(
                Repeat.self,
                from: ["--count", "4", "--counter", "world"],
                initial: Repeat()
            )
            #expect(parsed == Repeat(phrase: "world", count: 4, counter: true))
        }

        // MARK: - Error paths

        @Test
        func `Missing positional throws .missingPositional`() {
            do throws(Command.Error) {
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

        @Test
        func `Invalid Int value throws .invalidValue`() {
            do throws(Command.Error) {
                _ = try Command.parse(
                    Repeat.self,
                    from: ["--count", "not-num", "hi"],
                    initial: Repeat()
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

        @Test
        func `Unknown long option throws .unknownLongOption`() {
            do throws(Command.Error) {
                _ = try Command.parse(
                    Repeat.self,
                    from: ["--unknown", "x", "hi"],
                    initial: Repeat()
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

        @Test
        func `--help triggers .helpRequested`() {
            do throws(Command.Error) {
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
}
