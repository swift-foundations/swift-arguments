import Testing

@testable import Command_Test_Support

extension Argument.Tokenizer.Default {
    @Suite
    struct Test {

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
        func `--name value emits .long(name) then operand → .positional(value)`() throws(Command
            .Error)
        {
            let argv = ["--count", "3"]
            let tokens = try Argument.Tokenizer.Default().tokenize(argv)

            #expect(tokens.map(\.kind) == [.long("count"), .positional("3")])
        }

        @Test
        func `-f emits .shortCluster('f')`() throws(Command.Error) {
            let argv = ["-f"]
            let tokens = try Argument.Tokenizer.Default().tokenize(argv)

            #expect(tokens.map(\.kind) == [.shortCluster("f")])
        }

        @Test
        func `-fvalue emits .shortCluster('f') + .value('value') (Guideline 6)`() throws(Command
            .Error)
        {
            let argv = ["-fvalue"]
            let tokens = try Argument.Tokenizer.Default().tokenize(argv)

            #expect(tokens.map(\.kind) == [.shortCluster("f"), .value("value")])
        }

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
