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

/// Fixture command with one Int option whose default we expect to be
/// auto-derived from the seed instance's field value.
private struct AutoDefaultFixture: Command.`Protocol`, Equatable {
    var phrase: String
    var count: Int
    var counter: Bool

    init(phrase: String = "", count: Int = 7, counter: Bool = false) {
        self.phrase = phrase
        self.count = count
        self.counter = counter
    }

    static var configuration: Command.Configuration {
        Command.Configuration(name: "auto", abstract: "Auto-default fixture.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.phrase, name: "phrase")
            Command.Option(\.count, name: .longLiteral("count"))
            Command.Flag(\.counter, name: .longLiteral("counter"))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

/// Fixture with an Optional<Int> option: nil-default suppresses,
/// some(v) renders.
private struct OptionalIntFixture: Command.`Protocol`, Equatable {
    var port: Int?

    init(port: Int? = nil) {
        self.port = port
    }

    static var configuration: Command.Configuration {
        Command.Configuration(name: "opt", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option(\.port, name: .longLiteral("port"))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

@Suite("Command.Help — auto-derive defaults")
struct CommandHelpAutoDefaultTests {

    @Test("Int default auto-derived for Option")
    func intDefaultAutoDerived() {
        var buffer = ""
        Command.Help<AutoDefaultFixture>().serialize(
            AutoDefaultFixture.schema,
            into: &buffer,
            initial: AutoDefaultFixture()
        )
        #expect(buffer.contains("--count <count>"))
        #expect(buffer.contains("(default: 7)"))
    }

    @Test("String default auto-derived for Positional")
    func stringDefaultAutoDerivedForPositional() {
        var buffer = ""
        Command.Help<AutoDefaultFixture>().serialize(
            AutoDefaultFixture.schema,
            into: &buffer,
            initial: AutoDefaultFixture(phrase: "hello")
        )
        // The positional ARGUMENTS section should carry the default.
        #expect(buffer.contains("<phrase>"))
        #expect(buffer.contains("(default: hello)"))
    }

    @Test("Bool flag default NOT rendered")
    func boolFlagSuppressed() {
        var buffer = ""
        Command.Help<AutoDefaultFixture>().serialize(
            AutoDefaultFixture.schema,
            into: &buffer,
            initial: AutoDefaultFixture(counter: true)
        )
        // Flag line is present, but no '(default: true)' suffix.
        #expect(buffer.contains("--counter"))
        #expect(!buffer.contains("(default: true)"))
        #expect(!buffer.contains("(default: false)"))
    }

    @Test("Optional<Int> nil-default rendered with no default line")
    func optionalNilDefaultSuppressed() {
        var buffer = ""
        Command.Help<OptionalIntFixture>().serialize(
            OptionalIntFixture.schema,
            into: &buffer,
            initial: OptionalIntFixture(port: nil)
        )
        #expect(buffer.contains("--port"))
        #expect(!buffer.contains("(default:"))
    }

    @Test("Optional<Int> some(8080) renders default 8080")
    func optionalSomeDefaultRendered() {
        var buffer = ""
        Command.Help<OptionalIntFixture>().serialize(
            OptionalIntFixture.schema,
            into: &buffer,
            initial: OptionalIntFixture(port: 8080)
        )
        #expect(buffer.contains("--port"))
        #expect(buffer.contains("(default: 8080)"))
    }

    @Test("No-initial overload preserves v1.0.15 behavior — no auto-default")
    func noInitialOverloadPreservesBehavior() {
        var buffer = ""
        Command.Help<AutoDefaultFixture>().serialize(
            AutoDefaultFixture.schema,
            into: &buffer
        )
        // No initial → no auto-default suffix, even though the seed
        // would have `count = 7`.
        #expect(buffer.contains("--count <count>"))
        #expect(!buffer.contains("(default: 7)"))
    }
}
