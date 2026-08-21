import Testing

@testable import Command_Test_Support

private struct DocumentedCommand: Command.`Protocol`, Equatable {
    var input: String = ""
}

extension DocumentedCommand {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "documented",
            abstract: "A well-documented command.",
            discussion:
                "This command demonstrates the discussion section.\nMultiple lines are rendered indented.",
            aliases: ["doc", "docu"]
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.input, name: "input", help: .init(abstract: "Input value."))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

private struct PlainCommand: Command.`Protocol`, Equatable {
    var input: String = ""
}

extension PlainCommand {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "plain",
            abstract: "A plain command."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(\.input, name: "input", help: .init(abstract: "Input value."))
        }
    }

    mutating func run() async throws(Command.Error) {}
}

@Suite
struct `Command.Help AliasesAndDiscussion Tests` {

    @Test
    func `Help renders ALIASES section when aliases are non-empty`() {
        let help = Command.Help<DocumentedCommand>().serialize(DocumentedCommand.schema)
        #expect(help.contains("ALIASES: doc, docu"))
    }

    @Test
    func `Help renders DISCUSSION section when discussion is non-empty`() {
        let help = Command.Help<DocumentedCommand>().serialize(DocumentedCommand.schema)
        #expect(help.contains("DISCUSSION:"))
        #expect(help.contains("  This command demonstrates the discussion section."))
        #expect(help.contains("  Multiple lines are rendered indented."))
    }

    @Test
    func `Help omits ALIASES section when aliases are empty`() {
        let help = Command.Help<PlainCommand>().serialize(PlainCommand.schema)
        #expect(!help.contains("ALIASES:"))
    }

    @Test
    func `Help omits DISCUSSION section when discussion is empty`() {
        let help = Command.Help<PlainCommand>().serialize(PlainCommand.schema)
        #expect(!help.contains("DISCUSSION:"))
    }

    @Test
    func `Aliases and discussion appear in expected order`() {
        let help = Command.Help<DocumentedCommand>().serialize(DocumentedCommand.schema)

        let sections = ["USAGE:", "OVERVIEW:", "ALIASES:", "DISCUSSION:", "ARGUMENTS:"]
        var positions: [String: Int] = [:]
        for section in sections {

            let helpCount = help.count
            let needleCount = section.count
            guard helpCount >= needleCount else { continue }
            for offset in 0...(helpCount - needleCount) {
                let startIndex = help.index(help.startIndex, offsetBy: offset)
                let endIndex = help.index(startIndex, offsetBy: needleCount)
                if String(help[startIndex..<endIndex]) == section {
                    positions[section] = offset
                    break
                }
            }
        }

        guard let usagePos = positions["USAGE:"],
            let overviewPos = positions["OVERVIEW:"],
            let aliasesPos = positions["ALIASES:"],
            let discussionPos = positions["DISCUSSION:"],
            let argumentsPos = positions["ARGUMENTS:"]
        else {
            Issue.record("Missing section header in help text: \(help)")
            return
        }
        #expect(usagePos < overviewPos)
        #expect(overviewPos < aliasesPos)
        #expect(aliasesPos < discussionPos)
        #expect(discussionPos < argumentsPos)
    }
}
