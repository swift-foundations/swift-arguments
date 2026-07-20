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

/// End-to-end parse tests for D15 — `Optional<T>: Argument.Codable`.
///
/// Validates that schema-bound optional properties:
/// 1. Default to `nil` when the option is absent from argv.
/// 2. Carry `.some(value)` when present and the wrapped parse succeeds.
/// 3. Surface `Command.Error.invalidValue` when present with an invalid
///    argv value (matching the per-argument-decode failure model).
extension Command {
    @Suite
    struct `Optional Argument` {

        @Test
        func `Both options absent: retain nil defaults`() throws(Command.Error) {
            let parsed = try Command.parse(
                OptionalSchema.self,
                from: [],
                initial: OptionalSchema()
            )
            #expect(parsed == OptionalSchema(label: nil, count: nil))
        }

        @Test
        func `--label populates Optional<String> to .some`() throws(Command.Error) {
            let parsed = try Command.parse(
                OptionalSchema.self,
                from: ["--label", "hello"],
                initial: OptionalSchema()
            )
            #expect(parsed == OptionalSchema(label: "hello", count: nil))
        }

        @Test
        func `--count populates Optional<Int> to .some`() throws(Command.Error) {
            let parsed = try Command.parse(
                OptionalSchema.self,
                from: ["--count", "42"],
                initial: OptionalSchema()
            )
            #expect(parsed == OptionalSchema(label: nil, count: 42))
        }

        @Test
        func `Both options present`() throws(Command.Error) {
            let parsed = try Command.parse(
                OptionalSchema.self,
                from: ["--label", "x", "--count", "7"],
                initial: OptionalSchema()
            )
            #expect(parsed == OptionalSchema(label: "x", count: 7))
        }

        @Test
        func `--label= empty argv produces .some("")`() throws(Command.Error) {
            // The Optional<String> conformance delegates to String's
            // never-nil-returning init?(argument:), so an empty argv string
            // yields .some("") — distinguishable from .none (absence).
            let parsed = try Command.parse(
                OptionalSchema.self,
                from: ["--label", ""],
                initial: OptionalSchema()
            )
            #expect(parsed == OptionalSchema(label: "", count: nil))
        }

        @Test
        func `Invalid Int argv surfaces .invalidValue`() {
            do throws(Command.Error) {
                _ = try Command.parse(
                    OptionalSchema.self,
                    from: ["--count", "not-num"],
                    initial: OptionalSchema()
                )
                Issue.record("Expected invalidValue, parse succeeded")
            } catch {
                switch error {
                case .invalidValue:
                    break  // expected: Optional<Int>.init?(argument: "not-num") returns nil

                default:
                    Issue.record("Expected invalidValue, got \(error)")
                }
            }
        }

        @Test
        func `--count=value form populates Optional<Int>`() throws(Command.Error) {
            let parsed = try Command.parse(
                OptionalSchema.self,
                from: ["--count=99"],
                initial: OptionalSchema()
            )
            #expect(parsed == OptionalSchema(label: nil, count: 99))
        }
    }
}
