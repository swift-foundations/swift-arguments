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

/// Fixture for Command.Positional.Many — rest-positional shape:
/// `mycli file1 file2 file3 …`.
struct ManyPositional: Command.`Protocol`, Equatable {
    var files: [String]

    init(files: [String] = []) {
        self.files = files
    }
}

extension ManyPositional {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "many-positional", abstract: "Accept any number of file values.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional<Self, String>.Many(
                \.files,
                name: "files",
                help: .init(abstract: "Files to process.")
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}

/// Fixture for Command.Option.Many — `mycli --tag a --tag b --tag c`.
struct ManyOption: Command.`Protocol`, Equatable {
    var tags: [String]

    init(tags: [String] = []) {
        self.tags = tags
    }
}

extension ManyOption {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "many-option", abstract: "Accept repeated tag values.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option<Self, String>.Many(
                \.tags,
                name: .longLiteral("tag"),
                help: .init(abstract: "A tag (repeatable).")
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}

/// Fixture for `Command.Positional` (one fixed) + `Command.Positional.Many`
/// (rest) — ensures the cursor consumes fixed slots first then streams
/// remainder into the array.
struct MixedPositionals: Command.`Protocol`, Equatable {
    var command: String
    var arguments: [String]

    init(command: String = "", arguments: [String] = []) {
        self.command = command
        self.arguments = arguments
    }
}

extension MixedPositionals {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "mixed", abstract: "First fixed, rest variadic.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.command, name: "command")
            Command.Positional<Self, String>.Many(
                \.arguments,
                name: "arguments",
                help: .init(abstract: "Remaining arguments.")
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}
