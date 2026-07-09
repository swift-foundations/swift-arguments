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

extension Command.Diagnostic {
    @Suite("Command.Diagnostic — message rendering")
    struct Test {
        @Test
        func `Unknown long option renders Error: prefix + option name`() {
            let error: Command.Error = .unknownLongOption(
                name: "--missing",
                position: .init(argvIndex: 0, byteOffset: 0),
                suggestion: nil
            )
            let rendered = Command.Diagnostic.message(for: error)
            #expect(rendered.hasPrefix("Error: "))
            #expect(rendered.contains("--missing"))
        }

        @Test
        func `Validation failure surfaces the reason verbatim`() {
            let error: Command.Error = .validationFailed(reason: "Cross-field rule X")
            let rendered = Command.Diagnostic.message(for: error)
            #expect(rendered == "Error: Cross-field rule X")
        }

        @Test
        func `Version-requested renders just the version string`() {
            let error: Command.Error = .versionRequested(version: "1.2.3")
            let rendered = Command.Diagnostic.message(for: error)
            #expect(rendered == "1.2.3")
        }

        @Test
        func `Exit-with-message renders the message`() {
            let error: Command.Error = .exit(code: 7, message: "user cancel")
            let rendered = Command.Diagnostic.message(for: error)
            #expect(rendered == "user cancel")
        }

        @Test
        func `Missing-subcommand lists available names`() {
            let error: Command.Error = .missingSubcommand(available: ["a", "b", "c"])
            let rendered = Command.Diagnostic.message(for: error)
            #expect(rendered.contains("a"))
            #expect(rendered.contains("b"))
            #expect(rendered.contains("c"))
        }
    }
}

extension Command.Diagnostic.Test {
    @Suite
    struct `Exit Code` {
        @Test
        func `Help requests map to exit code 0`() {
            #expect(Command.Diagnostic.exitCode(for: .helpRequested) == 0)
            #expect(
                Command.Diagnostic.exitCode(
                    for: .helpRequestedForSubcommand(name: "x", rendered: "")
                ) == 0
            )
        }

        @Test
        func `Version request maps to exit code 0`() {
            #expect(Command.Diagnostic.exitCode(for: .versionRequested(version: "1.0.0")) == 0)
        }

        @Test
        func `Exit carries the consumer-supplied code`() {
            #expect(Command.Diagnostic.exitCode(for: .exit(code: 0, message: nil)) == 0)
            #expect(Command.Diagnostic.exitCode(for: .exit(code: 1, message: nil)) == 1)
            #expect(Command.Diagnostic.exitCode(for: .exit(code: 42, message: nil)) == 42)
        }

        @Test
        func `Argv-syntactic errors map to EX_USAGE (64)`() {
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
                .invalidValue(
                    name: "--x",
                    value: "bad",
                    position: .init(argvIndex: 0, byteOffset: 0)
                ),
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

        @Test
        func `Argument-wrapped errors map to 1`() {
            let inner = Argument.Error.invalidValue(
                name: "x",
                value: "y",
                position: .init(argvIndex: 0, byteOffset: 0)
            )
            #expect(Command.Diagnostic.exitCode(for: .argument(inner)) == 1)
        }
    }
}
