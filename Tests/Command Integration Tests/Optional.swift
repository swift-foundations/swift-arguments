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

/// Integration-test fixture covering D15 — `Optional<T>: Argument.Codable`.
///
/// `OptionalSchema` declares both `String?` and `Int?` properties so the
/// schema parser exercises the optional-binding path end-to-end. A
/// well-formed argv populates `.some(value)`; absent options leave the
/// property at its declared `nil` default. Invalid argv values surface
/// `Command.Error.invalidValue` per the standard parse-failure model.
struct OptionalSchema: Command.`Protocol`, Equatable {
    var label: String?
    var count: Int?

    init(label: String? = nil, count: Int? = nil) {
        self.label = label
        self.count = count
    }
}

extension OptionalSchema {
    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "opt",
            abstract: "Demonstrates optional-typed schema bindings."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option(
                \.label,
                name: .longLiteral("label"),
                help: .init(abstract: "An optional label.")
            )
            Command.Option(
                \.count,
                name: .longLiteral("count"),
                help: .init(abstract: "An optional count.")
            )
        }
    }

    mutating func run() async throws(Command.Error) {
        // No-op for tests.
    }
}
