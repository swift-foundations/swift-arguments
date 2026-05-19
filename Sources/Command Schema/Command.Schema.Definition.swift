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

// swiftlint:disable no_any_protocol_existential
// reason: schema heterogeneity is load-bearing — each node carries
// a distinct generic value type `V`; no protocol-with-AT shape
// collapses the heterogeneous list. The Visitor's double-dispatch
// via `Node.accept(_:)` recovers the static type per node.
extension Command.Schema {
    /// The schema-as-data root for one command at L3.
    ///
    /// `Command.Schema.Definition<Root>` is the L3 binding-aware schema
    /// for one command. It carries an ordered list of KeyPath-bound
    /// nodes (``Command/Positional``, ``Command/Option``,
    /// ``Command/Flag``) that drive both:
    ///
    /// - **Parse direction**: the schema-driven argv parser at
    ///   ``Command/Core`` walks the nodes and writes parsed values into a
    ///   `Root` instance via each node's KeyPath.
    /// - **Emit direction**: ``Command/Help`` (a Serializer.\`Protocol\`)
    ///   visits the same nodes and produces formatted help text.
    ///
    /// Per §2.2 of the design, ONE schema value drives both directions
    /// — no second source of truth between parse and emit.
    ///
    /// ## Heterogeneity
    ///
    /// `nodes` is `[any Command.Schema.Node<Root>]` because each
    /// `Positional<Root, V>` / `Option<Root, V>` carries a distinct
    /// generic value type `V`. The visitor's double-dispatch via
    /// `Node.accept(_:)` recovers the static value type at the call site;
    /// the existential is structural, not a typing loss.
    public struct Definition<Root: Sendable>: Sendable {
        /// The schema nodes in declaration order.
        public let nodes: [any Command.Schema.Node<Root>]

        /// Creates a definition from an ordered list of nodes.
        @inlinable
        public init(nodes: [any Command.Schema.Node<Root>]) {
            self.nodes = nodes
        }

        /// Creates a definition from a `@Command.Builder` closure.
        ///
        /// ## Example
        ///
        /// ```swift
        /// Command.Schema.Definition<Repeat> {
        ///     Command.Positional(\.phrase, help: .init(abstract: "..."))
        ///     Command.Option(\.count, name: .long("count"))
        ///     Command.Flag(\.counter, name: .long("counter"))
        /// }
        /// ```
        @inlinable
        public init(@Command.Builder<Root> _ build: () -> [any Command.Schema.Node<Root>]) {
            self.nodes = build()
        }

        /// Walks every node in declaration order, dispatching each to
        /// the visitor's typed `visit(...)` method via `Node.accept(_:)`.
        @inlinable
        public func accept<Visitor: Command.Schema.Visitor>(
            _ visitor: inout Visitor
        ) throws(Visitor.Failure) where Visitor.Root == Root {
            for node in nodes {
                try node.accept(&visitor)
            }
        }
    }
}
// swiftlint:enable no_any_protocol_existential
