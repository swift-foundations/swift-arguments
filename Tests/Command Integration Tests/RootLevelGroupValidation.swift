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

/// F-001 fixture: a trivial subcommand with no arguments of its own.
struct RootLevelGroupChild: Command.`Protocol`, Equatable {
}

extension RootLevelGroupChild {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "child", abstract: "A trivial child subcommand.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {}
    }

    mutating func run() async throws(Command.Error) {}
}

/// F-001 fixture: a parent command that (invalidly) combines a
/// root-level KeyPath-bound flag with a ``Command/Subcommand/Group``.
///
/// Before the F-001 fix, declaring this shape compiled and parsed
/// without complaint — but any root-level `--verbose` write was
/// silently discarded the moment `dispatchSubcommand(group:)` replaced
/// `root` wholesale with the matched binding's `parse(subArgv:)` result
/// (`Command.Schema.ParseVisitor.swift`, `finalize()` /
/// `dispatchSubcommand(group:)`). After the fix, ``Command/Schema/ParseVisitor/finalize()``
/// rejects this schema shape at parse time with
/// ``Command/Error/validationFailed(reason:)`` instead of silently
/// dropping the root-level value.
struct RootFlagWithGroup: Command.`Protocol`, Equatable {
    var verbose: Bool = false
    var selected: Selected = .child(RootLevelGroupChild())

    enum Selected: Equatable {
        case child(RootLevelGroupChild)
    }
}

extension RootFlagWithGroup {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "rootflagwithgroup",
            abstract: "Root-level flag combined with a Subcommand.Group (F-001 fixture)."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag(\.verbose, name: .longLiteral("verbose"), help: .init(abstract: "Verbose."))
            Command.Subcommand.Group {
                Command.Subcommand.Case(
                    "child",
                    initial: { RootLevelGroupChild() },
                    map: { Self(selected: .child($0)) }
                )
            }
        }
    }

    mutating func run() async throws(Command.Error) {}
}
