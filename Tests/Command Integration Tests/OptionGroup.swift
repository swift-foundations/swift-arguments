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

// MARK: - Shared fragment

/// Shared option fragment exercised across multiple subcommands.
///
/// `SharedRootOptions` declares the global `--root` option exactly once.
/// Every subcommand schema imports it via ``Command/OptionGroup`` rather
/// than redeclaring the option, demonstrating the D16 fix to the
/// repeated-options inflation problem surfaced by the M1-retarget
/// swift-package-graph migration.
struct SharedRootOptions: Sendable, Equatable {
    /// The repository root directory.
    var root: String = "."

    /// The fragment's own schema.
    ///
    /// Declared once; reused everywhere.
    static let schema: Command.Schema.Definition<Self> = .init {
        Command.Option(
            \.root,
            name: .longLiteral("root"),
            help: .init(abstract: "Repository root directory.")
        )
    }
}

// MARK: - Sub-commands using the shared fragment

/// First subcommand consuming the shared fragment.
struct OGBuild: Command.`Protocol`, Equatable {
    var options: SharedRootOptions = .init()
    var target: String = ""

    static var configuration: Command.Configuration {
        Command.Configuration(name: "build", abstract: "Build a target.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.OptionGroup(\.options, schema: SharedRootOptions.schema)
            Command.Positional(\.target, name: "target", help: .init(abstract: "Target name."))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

/// Second subcommand consuming the same shared fragment.
struct OGTest: Command.`Protocol`, Equatable {
    var options: SharedRootOptions = .init()
    var filter: String = ""

    static var configuration: Command.Configuration {
        Command.Configuration(name: "test", abstract: "Run tests.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.OptionGroup(\.options, schema: SharedRootOptions.schema)
            Command.Positional(\.filter, name: "filter", help: .init(abstract: "Test filter."))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

// MARK: - Parent dispatching to sub-commands

/// Parent command demonstrating D16 across a multi-subcommand surface.
///
/// The fragment is declared once in ``SharedRootOptions``; each
/// subcommand imports it via ``Command/OptionGroup`` without
/// redeclaring `--root`. Compare to swift-argument-parser's
/// `@OptionGroup` shape, but expressed as a value (not a property
/// wrapper).
enum OGCLI: Command.`Protocol`, Equatable {
    case build(OGBuild)
    case test(OGTest)

    static var configuration: Command.Configuration {
        Command.Configuration(name: "og", abstract: "Demonstrates option groups across subcommands.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Subcommand.Group {
                Command.Subcommand.Case(
                    "build",
                    initial: { OGBuild() },
                    map: Self.build
                )
                Command.Subcommand.Case(
                    "test",
                    initial: { OGTest() },
                    map: Self.test
                )
            }
        }
    }

    mutating func run() async throws(Command.Error) {}
}

// MARK: - Flat schema for non-subcommand integration

/// Top-level command with a single OptionGroup and a positional.
///
/// Exercises the OptionGroup mechanism at the root of a flat schema
/// (no subcommand wrapping), confirming the forwarder works against
/// `Command.parse` as well as the subcommand dispatch path.
struct OGFlat: Command.`Protocol`, Equatable {
    var options: SharedRootOptions = .init()
    var name: String = ""

    static var configuration: Command.Configuration {
        Command.Configuration(name: "ogflat", abstract: "Flat schema with one OptionGroup.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.OptionGroup(\.options, schema: SharedRootOptions.schema)
            Command.Positional(\.name, name: "name", help: .init(abstract: "A name."))
        }
    }

    mutating func run() async throws(Command.Error) {}
}
