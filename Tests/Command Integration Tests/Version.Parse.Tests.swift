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

/// A versioned command: `configuration.version` is non-empty so
/// `--version` is intercepted at parse time.
private struct Versioned: Command.`Protocol`, Equatable {
    var phrase: String = ""
}

extension Versioned {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "versioned",
            abstract: "A command with a version string.",
            version: "1.2.3"
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.phrase, name: "phrase", help: .init(abstract: "A phrase."))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

/// An unversioned command: `configuration.version` is empty, so
/// `--version` is NOT intercepted and falls through to the unknown-
/// option throw (matching swift-argument-parser's opt-in shape).
private struct Unversioned: Command.`Protocol`, Equatable {
    var phrase: String = ""
}

extension Unversioned {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "unversioned",
            abstract: "A command with no version string."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.phrase, name: "phrase", help: .init(abstract: "A phrase."))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

/// A parent command with a non-empty version and a subcommand group.
///
/// Exercises the dispatch path's `--version` interception (before any
/// subcommand is selected).
private enum VersionedParent: Command.`Protocol`, Equatable {
    case child(Child)
}

extension VersionedParent {
    struct Child: Command.`Protocol`, Equatable {
        var flag: Bool = false
    }
}

extension VersionedParent.Child {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "child", abstract: "A child subcommand.")
    }
    fileprivate static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag(\.flag, name: .longLiteral("flag"), help: .init(abstract: "A flag."))
        }
    }
    mutating func run() async throws(Command.Error) {}
}

extension VersionedParent {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "parent",
            abstract: "A parent command.",
            version: "4.5.6"
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Subcommand.Group {
                Command.Subcommand.Case("child", initial: { Child() }, map: Self.child)
            }
        }
    }

    mutating func run() async throws(Command.Error) {}
}

@Suite
struct Test {

    // Why these tests exist:
    //
    // Before B1 closure, `Command.Configuration.version` was declared at
    // Command.Configuration.swift:46 and propagated through the
    // subcommand-binding render path
    // (Command.Subcommand.Case+Command.Subcommand.Binding.swift:37), but
    // the ParseVisitor never intercepted `--version` — only `--help` /
    // `-h` were handled at ParseVisitor.swift:408,479. The field was
    // therefore declared-but-inert: setting `version:` had no observable
    // effect at parse time. The fixes below close that gap.

    @Test
    func `--version on a versioned command throws .versionRequested`() {
        do throws(Command.Error) {
            _ = try Command.parse(Versioned.self, from: ["--version"], initial: Versioned())
            Issue.record("Expected .versionRequested, parse succeeded")
        } catch {
            switch error {
            case .versionRequested(let version):
                #expect(version == "1.2.3")

            default:
                Issue.record("Expected .versionRequested, got \(error)")
            }
        }
    }

    @Test
    func `--version on an unversioned command throws .unknownLongOption`() {
        do throws(Command.Error) {
            _ = try Command.parse(Unversioned.self, from: ["--version"], initial: Unversioned())
            Issue.record("Expected .unknownLongOption, parse succeeded")
        } catch {
            switch error {
            case .unknownLongOption:
                break  // expected — matches Apple's behaviour

            default:
                Issue.record("Expected .unknownLongOption, got \(error)")
            }
        }
    }

    @Test
    func `--version on a parent with subcommand group is intercepted before dispatch`() {
        do throws(Command.Error) {
            _ = try Command.parse(
                VersionedParent.self,
                from: ["--version"],
                initial: VersionedParent.child(.init())
            )
            Issue.record("Expected .versionRequested, parse succeeded")
        } catch {
            switch error {
            case .versionRequested(let version):
                #expect(version == "4.5.6")

            default:
                Issue.record("Expected .versionRequested, got \(error)")
            }
        }
    }

    @Test
    func `.versionRequested case carries the version string`() {
        let error: Command.Error = .versionRequested(version: "9.8.7")
        switch error {
        case .versionRequested(let version):
            #expect(version == "9.8.7")

        default:
            Issue.record("Expected .versionRequested, got \(error)")
        }
    }
}
