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

@Suite("Argument.Tokenizer.Default")
struct ArgumentTokenizerDefaultTests {

    // MARK: - GNU long options (handled inline at L3)

    @Test("--long emits .long(name)")
    func longOptionBare() throws(Command.Error) {
        let argv = ["--verbose"]
        let tokens = try Argument.Tokenizer.Default().tokenize(argv)
        #expect(tokens.map(\.kind) == [.long("verbose")])
    }

    @Test("--name=value emits .long(name) + .value(v)")
    func longOptionEqualValue() throws(Command.Error) {
        let argv = ["--count=3"]
        let tokens = try Argument.Tokenizer.Default().tokenize(argv)
        #expect(tokens.map(\.kind) == [.long("count"), .value("3")])
    }

    @Test("--name value emits .long(name) then operand → .positional(value)")
    func longOptionSpaceValue() throws(Command.Error) {
        let argv = ["--count", "3"]
        let tokens = try Argument.Tokenizer.Default().tokenize(argv)
        // The L2 tokenizer classifies '3' as .operand since it's not option-shaped;
        // the L3 mapping table converts .operand to .positional.
        #expect(tokens.map(\.kind) == [.long("count"), .positional("3")])
    }

    // MARK: - POSIX short options (delegated to L2)

    @Test("-f emits .shortCluster('f')")
    func shortFlagSingleChar() throws(Command.Error) {
        let argv = ["-f"]
        let tokens = try Argument.Tokenizer.Default().tokenize(argv)
        // L2 emits .shortFlag('f'); L3 mapping normalizes to .shortCluster("f").
        #expect(tokens.map(\.kind) == [.shortCluster("f")])
    }

    @Test("-fvalue emits .shortCluster('f') + .value('value') (Guideline 6)")
    func shortFlagWithConcatenatedValue() throws(Command.Error) {
        let argv = ["-fvalue"]
        let tokens = try Argument.Tokenizer.Default().tokenize(argv)
        // L2 emits .shortFlag('f') + .shortValue('value');
        // L3 normalization gives .shortCluster + .value.
        #expect(tokens.map(\.kind) == [.shortCluster("f"), .value("value")])
    }

    // MARK: - Positionals + end-of-options

    @Test("Bare operand emits .positional")
    func operandIsPositional() throws(Command.Error) {
        let argv = ["hello"]
        let tokens = try Argument.Tokenizer.Default().tokenize(argv)
        #expect(tokens.map(\.kind) == [.positional("hello")])
    }

    @Test("-- emits .endOfOptions; subsequent argv emit .positional")
    func endOfOptionsSeparator() throws(Command.Error) {
        let argv = ["--", "--still-positional"]
        let tokens = try Argument.Tokenizer.Default().tokenize(argv)
        #expect(tokens.map(\.kind) == [.endOfOptions, .positional("--still-positional")])
    }

    // MARK: - Mixed canonical argv

    @Test("Mixed long-option + positional + flag argv")
    func mixedArgv() throws(Command.Error) {
        let argv = ["--count", "3", "--verbose", "hello"]
        let tokens = try Argument.Tokenizer.Default().tokenize(argv)
        #expect(
            tokens.map(\.kind) == [
                .long("count"),
                .positional("3"),
                .long("verbose"),
                .positional("hello"),
            ]
        )
    }
}
