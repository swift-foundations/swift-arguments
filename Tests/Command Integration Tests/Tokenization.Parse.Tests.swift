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

// MARK: - Gap 1 — Glued short-option value (POSIX 12.2 Guideline 6)

extension Command {
    @Suite
    struct `Glued Short Option` {

        @Test
        func `-Dfoo=bar binds 'foo=bar' to the short option -D`() throws(Command.Error) {
            let parsed = try Command.parse(
                GluedShortOptionD.self,
                from: ["-Dfoo=bar"],
                initial: .init()
            )
            #expect(parsed == GluedShortOptionD(define: "foo=bar"))
        }

        @Test
        func `-Xmx2g binds 'mx2g' to the short option -X (javac style)`() throws(Command.Error) {
            let parsed = try Command.parse(
                GluedShortOptionX.self,
                from: ["-Xmx2g"],
                initial: .init()
            )
            #expect(parsed == GluedShortOptionX(jvmFlag: "mx2g"))
        }

        @Test
        func `-fvalue regression check — single-char glued form still works`() throws(Command.Error) {
            let parsed = try Command.parse(
                GluedShortOptionF.self,
                from: ["-fvalue"],
                initial: .init()
            )
            #expect(parsed == GluedShortOptionF(flag: "value"))
        }
    }
}

// MARK: - Gap 2 — Negative-number positional

extension Command {
    @Suite
    struct `Negative Number Positional` {

        @Test
        func `-5 with a single Int positional binds value == -5`() throws(Command.Error) {
            let parsed = try Command.parse(
                NegativeIntPositional.self,
                from: ["-5"],
                initial: .init()
            )
            #expect(parsed == NegativeIntPositional(value: -5))
        }

        @Test
        func `-3.14 with a Float positional binds value == -3.14`() throws(Command.Error) {
            let parsed = try Command.parse(
                NegativeFloatPositional.self,
                from: ["-3.14"],
                initial: .init()
            )
            #expect(parsed == NegativeFloatPositional(value: -3.14))
        }

        @Test
        func `Schema-explicit -5 flag wins over numeric-positional heuristic`() throws(Command.Error) {
            // Schema declares `-5` as a Bool flag AND an Int positional.
            // Argv `["-5", "7"]`: the heuristic suppresses because `-5` IS a
            // schema-declared short flag → flag fires; positional reads "7".
            let parsed = try Command.parse(
                NegativeNumberWithFiveFlag.self,
                from: ["-5", "7"],
                initial: .init()
            )
            #expect(parsed == NegativeNumberWithFiveFlag(fiveFlag: true, value: 7))
        }
    }
}

// MARK: - Gap 3 — Did-you-mean suggestions

extension Command.Diagnostic.Suggestion {
    @Suite
    struct Test {

        @Test
        func `Unknown long option --buld suggests 'build'`() {
            do throws(Command.Error) {
                _ = try Command.parse(
                    BuildOptionCommand.self,
                    from: ["--buld"],
                    initial: .init()
                )
                Issue.record("Expected unknownLongOption throw")
            } catch {
                switch error {
                case .unknownLongOption(let name, _, let suggestion):
                    #expect(name == "--buld")
                    #expect(suggestion == "build")

                default:
                    Issue.record("Expected unknownLongOption, got \(error)")
                }
            }
        }

        @Test
        func `Unknown subcommand 'clne' suggests 'clone'`() {
            do throws(Command.Error) {
                _ = try Command.parse(
                    GitSuggest.self,
                    from: ["clne"],
                    initial: .clone(.init())
                )
                Issue.record("Expected unknownSubcommand throw")
            } catch {
                switch error {
                case .unknownSubcommand(let name, _, let suggestion):
                    #expect(name == "clne")
                    #expect(suggestion == "clone")

                default:
                    Issue.record("Expected unknownSubcommand, got \(error)")
                }
            }
        }

        @Test
        func `Far-from-any-declared-name '--xyz' carries nil suggestion`() {
            do throws(Command.Error) {
                _ = try Command.parse(
                    BuildOptionCommand.self,
                    from: ["--xyz"],
                    initial: .init()
                )
                Issue.record("Expected unknownLongOption throw")
            } catch {
                switch error {
                case .unknownLongOption(let name, _, let suggestion):
                    #expect(name == "--xyz")
                    #expect(suggestion == nil)

                default:
                    Issue.record("Expected unknownLongOption, got \(error)")
                }
            }
        }
    }
}
