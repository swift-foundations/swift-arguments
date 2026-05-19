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

/// The canonical end-to-end test fixture.
///
/// `Repeat` mirrors the swift-argument-parser introductory example: a
/// CLI that repeats an input phrase a configurable number of times,
/// optionally with a per-iteration counter prefix.
///
/// See the design doc §3.5 surface example. Used by the integration
/// tests as the load-bearing acceptance test for the full L3 stack.
struct Repeat: Command.`Protocol`, Equatable {
    var phrase: String
    var count: Int
    var counter: Bool

    init(phrase: String = "", count: Int = 2, counter: Bool = false) {
        self.phrase = phrase
        self.count = count
        self.counter = counter
    }

    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "repeat",
            abstract: "Repeats your input phrase."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional(
                \.phrase,
                name: "phrase",
                help: .init(abstract: "The phrase to repeat.")
            )
            Command.Option(
                \.count,
                name: .longLiteral("count"),
                help: .init(abstract: "The number of times to repeat 'phrase'.")
            )
            Command.Flag(
                \.counter,
                name: .longLiteral("counter"),
                help: .init(abstract: "Include a counter with each repetition.")
            )
        }
    }

    mutating func run() async throws(Command.Error) {
        // No-op for tests; the production `run()` would print phrases.
    }
}
