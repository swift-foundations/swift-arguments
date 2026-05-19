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

public import Serializer_Primitives_Core

extension Command {
    /// A help-text serializer over a ``Command/Schema/Definition``.
    ///
    /// `Command.Help<Root>` is a `Serializer.\`Protocol\`` conformer
    /// that emits formatted help text from a command schema. It walks
    /// the schema via ``Command/Help/Visitor`` and appends the
    /// rendered help text to a `String` buffer.
    ///
    /// ## Output shape
    ///
    /// The generated help text follows the swift-argument-parser format:
    ///
    /// ```
    /// USAGE: <name> [<options>] <positionals>
    ///
    /// ABSTRACT: <abstract>
    ///
    /// ARGUMENTS:
    ///   <positional>          <help abstract>
    ///
    /// OPTIONS:
    ///   --<name> <value>      <help abstract>
    ///   --<flag>              <help abstract>
    ///   -h, --help            Show help information.
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let helpText: String = try Command.Help<Repeat>().serialize(
    ///     Repeat.schema
    /// )
    /// ```
    public struct Help<Root: Command.`Protocol`>: Serializer.`Protocol` {
        public typealias Output = Command.Schema.Definition<Root>
        public typealias Buffer = Swift.String
        public typealias Failure = Never
        public typealias Body = Never

        /// Creates a help serializer.
        @inlinable
        public init() {}

        /// Walks the schema's nodes and appends formatted help text to
        /// `buffer`.
        ///
        /// Pure-text emission — cannot fail. Auto-derived defaults are
        /// not rendered on this overload; declarations whose
        /// ``Argument/Help/defaultDescription`` is `nil` will emit no
        /// default line.
        @inlinable
        public borrowing func serialize(
            _ output: Command.Schema.Definition<Root>,
            into buffer: inout Swift.String
        ) {
            var visitor = Command.Help<Root>.Visitor(configuration: Root.configuration)
            output.accept(&visitor)
            buffer += visitor.render()
        }

        /// Walks the schema's nodes and appends formatted help text to
        /// `buffer`, threading `initial` so the visitor can auto-derive
        /// default-value descriptions for declarations whose
        /// ``Argument/Help/defaultDescription`` is `nil`.
        ///
        /// Auto-derivation rules — when `initial` is non-`nil`:
        ///
        /// - `Positional<V>` / `Option<V>` (non-Optional / non-Array) —
        ///   render `(default: \(String(describing: value)))`.
        /// - `Positional.Many<V>` / `Option.Many<V>` — render only when
        ///   the initial array is non-empty.
        /// - Plain `Flag<Bool>` — never render (present/absent
        ///   semantics).
        /// - `Flag.Count<Int>` — render only when the initial counter
        ///   is non-zero.
        /// - `Flag.Inverted<Bool>` — render the long-option name
        ///   matching the initial value (e.g. `--no-feature` when
        ///   `initial = false`).
        /// - `Flag.Enumerable<E>` — render the case-flag name of the
        ///   initial enum case.
        /// - `Option<V?>` (`nil`) — never render.
        /// - `Option<V?>` (`some(v)`) — render `(default: \(String(describing: v)))`.
        ///
        /// User-supplied ``Argument/Help/defaultDescription`` always
        /// takes precedence over auto-derivation. Pass-through when the
        /// declaration's `help.defaultDescription` is already set.
        ///
        /// - Parameters:
        ///   - output: The schema to render.
        ///   - buffer: Mutable buffer the rendered text is appended to.
        ///   - initial: The seed `Root` value supplying defaults.
        @inlinable
        public borrowing func serialize(
            _ output: Command.Schema.Definition<Root>,
            into buffer: inout Swift.String,
            initial: Root
        ) {
            var visitor = Command.Help<Root>.Visitor(
                configuration: Root.configuration,
                initial: initial
            )
            output.accept(&visitor)
            buffer += visitor.render()
        }
    }
}
