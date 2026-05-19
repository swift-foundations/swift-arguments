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

@Suite("Command.Diagnostic — message rendering")
struct CommandDiagnosticMessageTests {
    @Test("Unknown long option renders Error: prefix + option name")
    func unknownLongOption() {
        let error: Command.Error = .unknownLongOption(
            name: "--missing",
            position: .init(argvIndex: 0, byteOffset: 0),
            suggestion: nil
        )
        let rendered = Command.Diagnostic.message(for: error)
        #expect(rendered.hasPrefix("Error: "))
        #expect(rendered.contains("--missing"))
    }

    @Test("Validation failure surfaces the reason verbatim")
    func validationFailedRendersReason() {
        let error: Command.Error = .validationFailed(reason: "Cross-field rule X")
        let rendered = Command.Diagnostic.message(for: error)
        #expect(rendered == "Error: Cross-field rule X")
    }

    @Test("Version-requested renders just the version string")
    func versionRequested() {
        let error: Command.Error = .versionRequested(version: "1.2.3")
        let rendered = Command.Diagnostic.message(for: error)
        #expect(rendered == "1.2.3")
    }

    @Test("Exit-with-message renders the message")
    func exitWithMessage() {
        let error: Command.Error = .exit(code: 7, message: "user cancel")
        let rendered = Command.Diagnostic.message(for: error)
        #expect(rendered == "user cancel")
    }

    @Test("Missing-subcommand lists available names")
    func missingSubcommandLists() {
        let error: Command.Error = .missingSubcommand(available: ["a", "b", "c"])
        let rendered = Command.Diagnostic.message(for: error)
        #expect(rendered.contains("a"))
        #expect(rendered.contains("b"))
        #expect(rendered.contains("c"))
    }
}

@Suite("Command.Diagnostic — exitCode mapping")
struct CommandDiagnosticExitCodeTests {
    @Test("Help requests map to exit code 0")
    func helpRequestedZero() {
        #expect(Command.Diagnostic.exitCode(for: .helpRequested) == 0)
        #expect(
            Command.Diagnostic.exitCode(
                for: .helpRequestedForSubcommand(name: "x", rendered: "")
            ) == 0
        )
    }

    @Test("Version request maps to exit code 0")
    func versionRequestedZero() {
        #expect(Command.Diagnostic.exitCode(for: .versionRequested(version: "1.0.0")) == 0)
    }

    @Test("Exit carries the consumer-supplied code")
    func exitCarriesCode() {
        #expect(Command.Diagnostic.exitCode(for: .exit(code: 0, message: nil)) == 0)
        #expect(Command.Diagnostic.exitCode(for: .exit(code: 1, message: nil)) == 1)
        #expect(Command.Diagnostic.exitCode(for: .exit(code: 42, message: nil)) == 42)
    }

    @Test("Argv-syntactic errors map to EX_USAGE (64)")
    func usageErrorsToSixtyFour() {
        let cases: [Command.Error] = [
            .unknownLongOption(
                name: "--x",
                position: .init(argvIndex: 0, byteOffset: 0),
                suggestion: nil
            ),
            .unknownShortOption(name: "x", position: .init(argvIndex: 0, byteOffset: 0)),
            .unknownSubcommand(
                name: "x",
                position: .init(argvIndex: 0, byteOffset: 0),
                suggestion: nil
            ),
            .missingOptionValue(name: "--x", position: .init(argvIndex: 0, byteOffset: 0)),
            .invalidValue(name: "--x", value: "bad", position: .init(argvIndex: 0, byteOffset: 0)),
            .missingPositional(name: "x", position: .init(argvIndex: 0, byteOffset: 0)),
            .missingSubcommand(available: []),
            .unexpectedPositional(value: "x", position: .init(argvIndex: 0, byteOffset: 0)),
            .validationFailed(reason: "x"),
            .tokenizer(reason: "x", argvIndex: 0),
        ]
        for error in cases {
            #expect(Command.Diagnostic.exitCode(for: error) == 64, "case \(error) → 64")
        }
    }

    @Test("Argument-wrapped errors map to 1")
    func argumentWrappedMapsToOne() {
        let inner = Argument.Error.invalidValue(
            name: "x",
            value: "y",
            position: .init(argvIndex: 0, byteOffset: 0)
        )
        #expect(Command.Diagnostic.exitCode(for: .argument(inner)) == 1)
    }
}
