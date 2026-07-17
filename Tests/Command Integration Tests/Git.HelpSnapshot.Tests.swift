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

    /// The exact help-text shape expected for `Git`.
    ///
    /// This is the canonical evidence cited in the P4 closeout report:
    /// the schema-driven help serializer produces a
    /// swift-argument-parser-shaped layout for a sum-type command
    /// declaring a ``Command/Subcommand/Group``.
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
