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

/// A value type used to exercise the `transform:` escape hatch on
/// schema-node binding inits.
///
/// Critically, this type does NOT conform to ``Argument/Codable``. It
/// stands in for value types the consumer does not own (e.g.
/// `Foundation.URL`, third-party value types) where the only path to a
/// schema-bound value is a custom argv-string parse closure supplied at
/// the call site.
struct TransformedHost: Sendable, Equatable {
    let scheme: String
    let host: String

    /// Parses `"scheme://host"` into a `TransformedHost`.
    ///
    /// Returns `nil` when the input doesn't contain `"://"` or either
    /// side is empty.
    ///
    /// Implemented via manual character scanning to avoid pulling in
    /// `Standard_Library_Extensions` (the `String.range(of:)` family
    /// requires it under the `#MemberImportVisibility` Swift 6 rule).
    static func parse(_ string: String) -> Self? {
        var schemeChars: [Character] = []
        var hostChars: [Character] = []
        var seenColon = false
        var seenFirstSlash = false
        var seenSecondSlash = false
        for character in string {
            if !seenColon {
                if character == ":" {
                    seenColon = true
                } else {
                    schemeChars.append(character)
                }
                continue
            }
            if !seenFirstSlash {
                guard character == "/" else { return nil }
                seenFirstSlash = true
                continue
            }
            if !seenSecondSlash {
                guard character == "/" else { return nil }
                seenSecondSlash = true
                continue
            }
            hostChars.append(character)
        }
        guard seenSecondSlash else { return nil }
        guard !schemeChars.isEmpty, !hostChars.isEmpty else { return nil }
        return Self(
            scheme: String(schemeChars),
            host: String(hostChars)
        )
    }
}

/// Fixture: `Command.Positional` bound to a non-Codable type via
/// `transform:` closure.
struct TransformedPositional: Command.`Protocol`, Equatable {
    var endpoint: TransformedHost

    init(endpoint: TransformedHost = TransformedHost(scheme: "", host: "")) {
        self.endpoint = endpoint
    }

    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "transformed-positional",
            abstract: "Bind a positional through a transform closure."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional<Self, TransformedHost>(
                \.endpoint,
                name: "endpoint",
                help: .init(abstract: "The endpoint in scheme://host form."),
                transform: { string throws(Command.Error) in
                    guard let parsed = TransformedHost.parse(string) else {
                        throw .invalidValue(
                            name: "endpoint",
                            value: string,
                            position: .init(argvIndex: 0, byteOffset: 0)
                        )
                    }
                    return parsed
                }
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}

/// Fixture: `Command.Option` bound to a non-Codable type via
/// `transform:` closure.
struct TransformedOption: Command.`Protocol`, Equatable {
    var endpoint: TransformedHost

    init(endpoint: TransformedHost = TransformedHost(scheme: "", host: "")) {
        self.endpoint = endpoint
    }

    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "transformed-option",
            abstract: "Bind an option through a transform closure."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option<Self, TransformedHost>(
                \.endpoint,
                name: .longLiteral("endpoint"),
                help: .init(abstract: "The endpoint in scheme://host form."),
                transform: { string throws(Command.Error) in
                    guard let parsed = TransformedHost.parse(string) else {
                        throw .invalidValue(
                            name: "--endpoint",
                            value: string,
                            position: .init(argvIndex: 0, byteOffset: 0)
                        )
                    }
                    return parsed
                }
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}

/// Fixture: `Command.Positional.Many` bound to a non-Codable element
/// type via `transform:` closure.
struct TransformedPositionalMany: Command.`Protocol`, Equatable {
    var endpoints: [TransformedHost]

    init(endpoints: [TransformedHost] = []) {
        self.endpoints = endpoints
    }

    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "transformed-positional-many",
            abstract: "Bind a rest-positional through a transform closure."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Positional<Self, TransformedHost>.Many(
                \.endpoints,
                name: "endpoints",
                help: .init(abstract: "Endpoint values in scheme://host form."),
                transform: { string throws(Command.Error) in
                    guard let parsed = TransformedHost.parse(string) else {
                        throw .invalidValue(
                            name: "endpoints",
                            value: string,
                            position: .init(argvIndex: 0, byteOffset: 0)
                        )
                    }
                    return parsed
                }
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}

/// Fixture: `Command.Option.Many` bound to a non-Codable element type
/// via `transform:` closure.
struct TransformedOptionMany: Command.`Protocol`, Equatable {
    var endpoints: [TransformedHost]

    init(endpoints: [TransformedHost] = []) {
        self.endpoints = endpoints
    }

    static var configuration: Command.Configuration {
        Command.Configuration(
            name: "transformed-option-many",
            abstract: "Bind a repeatable option through a transform closure."
        )
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Option<Self, TransformedHost>.Many(
                \.endpoints,
                name: .longLiteral("endpoint"),
                help: .init(abstract: "Endpoint values in scheme://host form."),
                transform: { string throws(Command.Error) in
                    guard let parsed = TransformedHost.parse(string) else {
                        throw .invalidValue(
                            name: "--endpoint",
                            value: string,
                            position: .init(argvIndex: 0, byteOffset: 0)
                        )
                    }
                    return parsed
                }
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}
