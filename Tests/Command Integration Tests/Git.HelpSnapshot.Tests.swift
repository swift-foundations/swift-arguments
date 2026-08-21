import Testing

@testable import Command_Test_Support

extension Git {
    @Suite
    struct HelpSnapshot {

        private static let expectedTopLevel: String = """
            USAGE: git <subcommand>

            OVERVIEW: Distributed version control.

            OPTIONS:
              -h, --help                Show help information.

            SUBCOMMANDS:
              clone                     Clone a repository.
              status                    Show working-tree status.

              See 'git help <subcommand>' for detailed help.

            """

        @Test
        func `Top-level help-text matches the expected snapshot exactly`() {
            let actual = Command.Help<Git>().serialize(Git.schema)
            #expect(actual == Self.expectedTopLevel)
        }
    }
}
