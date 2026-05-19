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

import Command_Test_Support

/// Fixture: a command that does NOT shadow `validate()` — exercises the
/// no-op default extension method.
struct ValidateNoOp: Command.`Protocol`, Equatable {
    var phrase: String

    init(phrase: String = "") {
        self.phrase = phrase
    }

    static var configuration: Command.Configuration {
        Command.Configuration(name: "validate-no-op", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.phrase, name: "phrase")
        }
    }

    mutating func run() async throws(Command.Error) {
        // No-op.
    }
}

/// Fixture: a command that shadows `validate()` with a cross-field check
/// that fails when both `--mode=local` and `--remote=true` are set.
struct ValidateCrossField: Command.`Protocol`, Equatable {
    var mode: String
    var remote: Bool

    init(mode: String = "local", remote: Bool = false) {
        self.mode = mode
        self.remote = remote
    }

    static var configuration: Command.Configuration {
        Command.Configuration(name: "validate-cross", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option(\.mode, name: .longLiteral("mode"))
            Command.Flag(\.remote, name: .longLiteral("remote"))
        }
    }

    /// Shadows the extension-default `validate()`.
    mutating func validate() throws(Command.Error) {
        if mode == "local" && remote {
            throw .validationFailed(
                reason: "Cannot combine --mode=local with --remote."
            )
        }
    }

    mutating func run() async throws(Command.Error) {
        // No-op.
    }
}
