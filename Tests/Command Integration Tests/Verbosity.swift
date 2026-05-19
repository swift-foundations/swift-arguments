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

import Command_Test_Support

/// Fixture for Command.Flag.Count — `mycli -vvv` increments verbosity.
struct Verbosity: Command.`Protocol`, Equatable {
    var level: Int

    init(level: Int = 0) {
        self.level = level
    }

    static var configuration: Command.Configuration {
        Command.Configuration(name: "verbosity", abstract: "Count-flag verbosity demo.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag<Self>.Count(
                \.level,
                name: .bothLiteral(short: "v", long: "verbose"),
                help: .init(abstract: "Increase verbosity (repeatable).")
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}
