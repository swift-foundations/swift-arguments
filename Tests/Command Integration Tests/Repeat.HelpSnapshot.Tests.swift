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

@Suite
struct Test {

    /// The exact help-text shape expected for `Repeat`.
    ///
    /// This is the canonical evidence cited in the closeout report:
    /// the schema-driven help serializer produces a readable
    /// swift-argument-parser-shaped layout for the canonical fixture.
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
