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

@Suite("Repeat — help-text emission")
struct RepeatHelpTests {

    @Test("Command.Help renders USAGE line with command name")
    func helpUsageLine() {
        let help = Command.Help<Repeat>().serialize(Repeat.schema)
        #expect(help.contains("USAGE: repeat"))
    }

    @Test("Command.Help includes OVERVIEW from configuration abstract")
    func helpOverview() {
        let help = Command.Help<Repeat>().serialize(Repeat.schema)
        #expect(help.contains("OVERVIEW: Repeats your input phrase."))
    }

    @Test("Command.Help includes ARGUMENTS section with positional")
    func helpArgumentsSection() {
        let help = Command.Help<Repeat>().serialize(Repeat.schema)
        #expect(help.contains("ARGUMENTS:"))
        #expect(help.contains("<phrase>"))
        #expect(help.contains("The phrase to repeat."))
    }

    @Test("Command.Help includes OPTIONS section with --count and --counter")
    func helpOptionsSection() {
        let help = Command.Help<Repeat>().serialize(Repeat.schema)
        #expect(help.contains("OPTIONS:"))
        #expect(help.contains("--count"))
        #expect(help.contains("--counter"))
        #expect(help.contains("The number of times to repeat 'phrase'."))
        #expect(help.contains("Include a counter with each repetition."))
    }

    @Test("Command.Help includes the built-in --help row")
    func helpIncludesHelpRow() {
        let help = Command.Help<Repeat>().serialize(Repeat.schema)
        #expect(help.contains("-h, --help"))
        #expect(help.contains("Show help information."))
    }
}
