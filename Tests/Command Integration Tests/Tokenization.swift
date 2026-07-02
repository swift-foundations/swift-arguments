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

// MARK: - Gap 1 fixtures (glued short-option value)

/// Fixture: schema with a short option `-D` taking a string value.
///
/// Models the POSIX 12.2 Guideline 6 concatenated-value form
/// (`-Dfoo=bar`, `cc -Dname=value`). The schema declares `-D` as a
/// short-only option with a string-typed value; the parse path verifies
/// the L3 dispatch (with splice-fold suppression) routes the
/// concatenated value to the option.
struct GluedShortOptionD: Command.`Protocol`, Equatable {
    var define: String

    init(define: String = "") {
        self.define = define
    }

    static var configuration: Command.Configuration {
        Command.Configuration(name: "glued-d", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option(\.define, name: .shortLiteral("D"))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

/// Fixture: schema with a short option `-X` taking a string value.
///
/// Models the `javac -Xmx2g` style (`-X` short option binds the
/// `mx2g` value via Guideline 6 concatenation).
struct GluedShortOptionX: Command.`Protocol`, Equatable {
    var jvmFlag: String

    init(jvmFlag: String = "") {
        self.jvmFlag = jvmFlag
    }

    static var configuration: Command.Configuration {
        Command.Configuration(name: "glued-x", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option(\.jvmFlag, name: .shortLiteral("X"))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

/// Fixture: schema with a short option `-f` taking a string value.
///
/// Regression check that the single-char glued form (`-fvalue`) still
/// works after Gap 1 / Gap 2 changes — this was the original
/// Guideline 6 test case and must remain green.
struct GluedShortOptionF: Command.`Protocol`, Equatable {
    var flag: String

    init(flag: String = "") {
        self.flag = flag
    }

    static var configuration: Command.Configuration {
        Command.Configuration(name: "glued-f", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option(\.flag, name: .shortLiteral("f"))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

// MARK: - Gap 2 fixtures (negative-number positional)

/// Fixture: schema with a single Int positional.
///
/// Verifies the negative-number positional heuristic (`seq -5 5`,
/// `bc -2`) routes a `-5`-shaped argv element to the Int positional
/// rather than throwing `unknownShortOption` for the digit `5`.
struct NegativeIntPositional: Command.`Protocol`, Equatable {
    var value: Int

    init(value: Int = 0) {
        self.value = value
    }

    static var configuration: Command.Configuration {
        Command.Configuration(name: "neg-int", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.value, name: "value")
        }
    }

    mutating func run() async throws(Command.Error) {}
}

/// Fixture: schema with a single Float positional.
///
/// Verifies the negative-number positional heuristic handles
/// fractional / multi-segment argv elements like `-3.14` (which
/// tokenizes as `.shortCluster("3")` + `.value(".14")` and must
/// re-route as the positional value `"-3.14"`).
struct NegativeFloatPositional: Command.`Protocol`, Equatable {
    var value: Float

    init(value: Float = 0) {
        self.value = value
    }

    static var configuration: Command.Configuration {
        Command.Configuration(name: "neg-float", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.value, name: "value")
        }
    }

    mutating func run() async throws(Command.Error) {}
}

/// Fixture: schema with a single Int positional AND a Bool flag named
/// `-5`.
///
/// Verifies schema-explicit-wins: when the schema declares a short
/// binding for the digit `5`, the negative-number positional heuristic
/// suppresses and the flag dispatches normally.
struct NegativeNumberWithFiveFlag: Command.`Protocol`, Equatable {
    var fiveFlag: Bool
    var value: Int

    init(fiveFlag: Bool = false, value: Int = 0) {
        self.fiveFlag = fiveFlag
        self.value = value
    }

    static var configuration: Command.Configuration {
        Command.Configuration(name: "flag-five", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag(\.fiveFlag, name: .shortLiteral("5"))
            Command.Positional(\.value, name: "value")
        }
    }

    mutating func run() async throws(Command.Error) {}
}

// MARK: - Gap 3 fixtures (did-you-mean suggestions)

/// Fixture: schema with a `--build` long option.
///
/// The suggestion path matches `--buld` → `build` via Levenshtein
/// distance 1.
struct BuildOptionCommand: Command.`Protocol`, Equatable {
    var build: Bool

    init(build: Bool = false) {
        self.build = build
    }

    static var configuration: Command.Configuration {
        Command.Configuration(name: "buildcmd", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag(\.build, name: .longLiteral("build"))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

/// Subcommand fixture used to exercise the unknown-subcommand
/// suggestion path.
///
/// Three concrete subcommands (`clone`, `commit`, `checkout`) so `clne`
/// should suggest `clone`.
struct GitSuggestClone: Command.`Protocol`, Equatable {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "clone", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {}
    }

    mutating func run() async throws(Command.Error) {}
}

struct GitSuggestCommit: Command.`Protocol`, Equatable {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "commit", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {}
    }

    mutating func run() async throws(Command.Error) {}
}

struct GitSuggestCheckout: Command.`Protocol`, Equatable {
    static var configuration: Command.Configuration {
        Command.Configuration(name: "checkout", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {}
    }

    mutating func run() async throws(Command.Error) {}
}

/// Sum-type root command for the suggestion subcommand test.
enum GitSuggest: Command.`Protocol`, Equatable {
    case clone(GitSuggestClone)
    case commit(GitSuggestCommit)
    case checkout(GitSuggestCheckout)

    static var configuration: Command.Configuration {
        Command.Configuration(name: "git", abstract: "")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Subcommand.Group {
                Command.Subcommand.Case(
                    "clone",
                    initial: { GitSuggestClone() },
                    map: Self.clone
                )
                Command.Subcommand.Case(
                    "commit",
                    initial: { GitSuggestCommit() },
                    map: Self.commit
                )
                Command.Subcommand.Case(
                    "checkout",
                    initial: { GitSuggestCheckout() },
                    map: Self.checkout
                )
            }
        }
    }

    mutating func run() async throws(Command.Error) {}
}
