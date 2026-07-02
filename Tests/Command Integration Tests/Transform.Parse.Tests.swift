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

/// End-to-end parse tests for the `transform:` closure escape hatch on
/// the four KeyPath-bound schema-node types.
///
/// Each test parses an argv stream against a fixture whose value type
/// (``TransformedHost``) does NOT conform to ``Argument/Codable``. The
/// schema's binding is created with a `transform:` closure that converts
/// the argv-element string into the bound value type — exercising the
/// drop-the-Codable-constraint init overload across
/// ``Command/Positional``, ``Command/Option``,
/// ``Command/Positional/Many``, and ``Command/Option/Many``.
@Suite("Transform-closure escape hatch — parse")
struct TransformParseTests {

    @Test("Command.Positional + transform: parses non-Codable value")
    func positionalTransformParses() throws(Command.Error) {
        let parsed = try Command.parse(
            TransformedPositional.self,
            from: ["https://example.com"],
            initial: TransformedPositional()
        )
        #expect(parsed.endpoint == TransformedHost(scheme: "https", host: "example.com"))
    }

    @Test("Command.Positional + transform: throws .invalidValue on malformed input")
    func positionalTransformInvalidValue() {
        #expect(throws: Command.Error.self) {
            _ = try Command.parse(
                TransformedPositional.self,
                from: ["malformed-no-separator"],
                initial: TransformedPositional()
            )
        }
    }

    @Test("Command.Option + transform: parses non-Codable value")
    func optionTransformParses() throws(Command.Error) {
        let parsed = try Command.parse(
            TransformedOption.self,
            from: ["--endpoint", "https://example.com"],
            initial: TransformedOption()
        )
        #expect(parsed.endpoint == TransformedHost(scheme: "https", host: "example.com"))
    }

    @Test("Command.Option + transform: throws .invalidValue on malformed input")
    func optionTransformInvalidValue() {
        #expect(throws: Command.Error.self) {
            _ = try Command.parse(
                TransformedOption.self,
                from: ["--endpoint", "no-scheme-separator"],
                initial: TransformedOption()
            )
        }
    }

    @Test("Command.Positional.Many + transform: parses multiple non-Codable values")
    func positionalManyTransformParses() throws(Command.Error) {
        let parsed = try Command.parse(
            TransformedPositionalMany.self,
            from: ["https://a.com", "http://b.org", "ftp://c.net"],
            initial: TransformedPositionalMany()
        )
        #expect(
            parsed.endpoints == [
                TransformedHost(scheme: "https", host: "a.com"),
                TransformedHost(scheme: "http", host: "b.org"),
                TransformedHost(scheme: "ftp", host: "c.net"),
            ]
        )
    }

    @Test("Command.Positional.Many + transform: empty argv → empty array")
    func positionalManyTransformEmpty() throws(Command.Error) {
        let parsed = try Command.parse(
            TransformedPositionalMany.self,
            from: [],
            initial: TransformedPositionalMany()
        )
        #expect(parsed.endpoints == [])
    }

    @Test("Command.Option.Many + transform: parses multiple non-Codable values")
    func optionManyTransformParses() throws(Command.Error) {
        let parsed = try Command.parse(
            TransformedOptionMany.self,
            from: [
                "--endpoint", "https://a.com",
                "--endpoint", "http://b.org",
                "--endpoint", "ftp://c.net",
            ],
            initial: TransformedOptionMany()
        )
        #expect(
            parsed.endpoints == [
                TransformedHost(scheme: "https", host: "a.com"),
                TransformedHost(scheme: "http", host: "b.org"),
                TransformedHost(scheme: "ftp", host: "c.net"),
            ]
        )
    }

    @Test("Command.Option.Many + transform: zero occurrences → empty array")
    func optionManyTransformEmpty() throws(Command.Error) {
        let parsed = try Command.parse(
            TransformedOptionMany.self,
            from: [],
            initial: TransformedOptionMany()
        )
        #expect(parsed.endpoints == [])
    }
}
