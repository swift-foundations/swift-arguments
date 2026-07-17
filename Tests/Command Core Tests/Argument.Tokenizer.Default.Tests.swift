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

extension Argument.Tokenizer.Default {
    @Suite
    struct Test {

        // MARK: - GNU long options (handled inline at L3)

        @Test
        func `--long emits .long(name)`() throws(Command.Error) {
            let argv = ["--verbose"]
            let tokens = try Argument.Tokenizer.Default().tokenize(argv)
            #expect(tokens.map(\.kind) == [.long("verbose")])
        }

        @Test
        func `--name=value emits .long(name) + .value(v)`() throws(Command.Error) {
            let argv = ["--count=3"]
            let tokens = try Argument.Tokenizer.Default().tokenize(argv)
            #expect(tokens.map(\.kind) == [.long("count"), .value("3")])
        }

        @Test
        func `--name value emits .long(name) then operand → .positional(value)`() throws(Command.Error) {
            let argv = ["--count", "3"]
            let tokens = try Argument.Tokenizer.Default().tokenize(argv)
            // The L2 tokenizer classifies '3' as .operand since it's not option-shaped;
            // the L3 mapping table converts .operand to .positional.
            #expect(tokens.map(\.kind) == [.long("count"), .positional("3")])
        }

        // MARK: - POSIX short options (delegated to L2)

        @Test
        func `-f emits .shortCluster('f')`() throws(Command.Error) {
            let argv = ["-f"]
            let tokens = try Argument.Tokenizer.Default().tokenize(argv)
            // L2 emits .shortFlag('f'); L3 mapping normalizes to .shortCluster("f").
            #expect(tokens.map(\.kind) == [.shortCluster("f")])
        }

        @Test
        func `-fvalue emits .shortCluster('f') + .value('value') (Guideline 6)`() throws(Command.Error) {
            let argv = ["-fvalue"]
            let tokens = try Argument.Tokenizer.Default().tokenize(argv)
            // L2 emits .shortFlag('f') + .shortValue('value');
            // L3 normalization gives .shortCluster + .value.
            #expect(tokens.map(\.kind) == [.shortCluster("f"), .value("value")])
        }

        // MARK: - Positionals + end-of-options

        @Test
        func `Bare operand emits .positional`() throws(Command.Error) {
            let argv = ["hello"]
            let tokens = try Argument.Tokenizer.Default().tokenize(argv)
            #expect(tokens.map(\.kind) == [.positional("hello")])
        }

        @Test
        func `-- emits .endOfOptions; subsequent argv emit .positional`() throws(Command.Error) {
            let argv = ["--", "--still-positional"]
            let tokens = try Argument.Tokenizer.Default().tokenize(argv)
            #expect(tokens.map(\.kind) == [.endOfOptions, .positional("--still-positional")])
        }

        // MARK: - Mixed canonical argv

        @Test
        func `Mixed long-option + positional + flag argv`() throws(Command.Error) {
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
}
