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

extension Command.Subcommand.Case: Command.Subcommand.Binding {
    /// Parses the sub-argv slice into the matching `Root` enum case.
    ///
    /// Calls ``Command/parse(_:from:initial:)`` against the sub-command's
    /// own schema (via `Sub.schema` from ``Command/Protocol``), then
    /// wraps the result via this case's `map` closure.
    @inlinable
    public func parse(subArgv: [String]) throws(Command.Error) -> Root {
        let parsed = try Command.parse(Sub.self, from: subArgv, initial: initial())
        return map(parsed)
    }

    /// Appends formatted help text for `Sub.schema` into `buffer`.
    ///
    /// Renders sub-help using a Schema-internal help visitor
    /// (``Command/Subcommand/Help/Visitor``) with the configuration's
    /// `name` overridden to the full invocation path (e.g., `"git clone"`
    /// rather than the bare subcommand name) so the USAGE line reads
    /// naturally.
    @inlinable
    public func appendHelp(to buffer: inout String, fullCommandName: String) {
        let configuration = Command.Configuration(
            name: fullCommandName,
            abstract: Sub.configuration.abstract,
            discussion: Sub.configuration.discussion,
            version: Sub.configuration.version,
            aliases: Sub.configuration.aliases
        )
        var visitor = Command.Subcommand.Help.Visitor<Sub>(configuration: configuration)
        Sub.schema.accept(&visitor)
        buffer += visitor.render()
    }
}
