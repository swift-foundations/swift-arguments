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
extension Command {
    /// The result-builder for ``Command/Schema/Definition``.
    ///
    /// `@Command.Builder<Root>` aggregates KeyPath-bound schema nodes
    /// into the ordered `[any Command.Schema.Node<Root>]` list that
    /// ``Command/Schema/Definition/init(_:)-shvr`` consumes.
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
    @resultBuilder
    public enum Builder<Root: Sendable> {
        /// Composes node statements into a single ordered list.
        public static func buildBlock(
            _ nodes: any Command.Schema.Node<Root>...
        ) -> [any Command.Schema.Node<Root>] {
            nodes
        }

        /// Treats a single node statement as a list of length one.
        public static func buildExpression<N: Command.Schema.Node>(
            _ node: N
        ) -> any Command.Schema.Node<Root> where N.Root == Root {
            node
        }

        /// Allows `if`/`else` branches in the builder.
        public static func buildEither(
            first: [any Command.Schema.Node<Root>]
        ) -> [any Command.Schema.Node<Root>] {
            first
        }

        /// Allows `if`/`else` branches in the builder.
        public static func buildEither(
            second: [any Command.Schema.Node<Root>]
        ) -> [any Command.Schema.Node<Root>] {
            second
        }

        /// Allows `if` without `else` in the builder.
        public static func buildOptional(
            _ component: [any Command.Schema.Node<Root>]?
        ) -> [any Command.Schema.Node<Root>] {
            component ?? []
        }

        /// Allows array-of-nodes literals in the builder.
        public static func buildArray(
            _ components: [[any Command.Schema.Node<Root>]]
        ) -> [any Command.Schema.Node<Root>] {
            components.flatMap(\.self)
        }
    }
}
// swiftlint:enable no_any_protocol_existential
