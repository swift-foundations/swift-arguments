import Testing

@testable import Command_Test_Support

extension Repeat {
    @Suite
    struct HelpSnapshot {

        private static let expected: String = """
            USAGE: repeat [--count <count>] [--counter] <phrase>

            OVERVIEW: Repeats your input phrase.

            ARGUMENTS:
              <phrase>                  The phrase to repeat.

            OPTIONS:
              --count <count>           The number of times to repeat 'phrase'.
              --counter                 Include a counter with each repetition.
              -h, --help                Show help information.

            """

        @Test
        func `Help-text matches the expected snapshot exactly`() {
            let actual = Command.Help<Repeat>().serialize(Repeat.schema)
            #expect(actual == Self.expected)
        }
    }
}
