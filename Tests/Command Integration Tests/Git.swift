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

/// Subcommand-dispatch fixture: a minimal Git-shaped sum-type command.
///
/// `Git` mirrors the swift-argument-parser Git example from the design
/// doc §3.5 — a parent command with two subcommands (`clone`, `status`)
/// that dispatch via `Parser.OneOf`-shaped sum-type selection.
///
/// The fixture serves as the load-bearing P4 acceptance test for the
/// subcommand-dispatch surface: a successful parse routes argv to the
/// matching `Sub` command schema and lifts the parsed value into the
/// `Git` enum's matching case.

/// A `clone`-shaped sub-command with one positional URL.
struct Clone: Command.`Protocol`, Equatable {
    var url: String

    init(url: String = "") {
        self.url = url
    }

    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "clone",
            abstract: "Clone a repository."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(
                \.url,
                name: "url",
                help: .init(abstract: "Repository URL.")
            )
        }
    }

    mutating func run() async throws(Command.Error) {
        // No-op for tests.
    }
}

/// A `status`-shaped sub-command with one boolean flag.
struct Status: Command.`Protocol`, Equatable {
    var short: Bool

    init(short: Bool = false) {
        self.short = short
    }

    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "status",
            abstract: "Show working-tree status."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag(
                \.short,
                name: .longLiteral("short"),
                help: .init(abstract: "Short format.")
            )
        }
    }

    mutating func run() async throws(Command.Error) {
        // No-op for tests.
    }
}

/// A `git`-shaped parent command: a sum type with two subcommand cases.
enum Git: Command.`Protocol`, Equatable {
    case clone(Clone)
    case status(Status)

    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "git",
            abstract: "Distributed version control."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Subcommand.Group {
                Command.Subcommand.Case(
                    "clone",
                    help: .init(abstract: "Clone a repository."),
                    initial: { Clone() },
                    map: Self.clone
                )
                Command.Subcommand.Case(
                    "status",
                    help: .init(abstract: "Show working-tree status."),
                    initial: { Status() },
                    map: Self.status
                )
            }
        }
    }

    mutating func run() async throws(Command.Error) {
        switch self {
        case .clone(var c):
            try await c.run()
            self = .clone(c)

        case .status(var s):
            try await s.run()
            self = .status(s)
        }
    }
}
