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
// reason: subcommand-binding heterogeneity is load-bearing — see the
// matching comment in ``Command/Subcommand/Group``.
extension Command.Subcommand.Group {
    /// The result-builder for ``Command/Subcommand/Group``.
    ///
    /// `@Command.Subcommand.Group.Builder` aggregates
    /// ``Command/Subcommand/Binding`` statements into the
    /// `[any Command.Subcommand.Binding<Root>]` list that
    /// ``Command/Subcommand/Group/init(_:)-shvr`` consumes.
    ///
    /// The Builder inherits the `Root` generic parameter from the
    /// enclosing ``Command/Subcommand/Group`` type — `Root` is in
    /// scope without re-declaration.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Command.Subcommand.Group {
    ///     Command.Subcommand.Case("clone", initial: Clone.init, map: Git.clone)
    ///     Command.Subcommand.Case("status", initial: Status.init, map: Git.status)
    /// }
    /// ```
    @resultBuilder
    public enum Builder {
        /// Composes binding statements into a single ordered list.
        public static func buildBlock(
            _ bindings: any Command.Subcommand.Binding<Root>...
        ) -> [any Command.Subcommand.Binding<Root>] {
            bindings
        }

        /// Treats a single binding statement as a list of length one.
        public static func buildExpression<B: Command.Subcommand.Binding>(
            _ binding: B
        ) -> any Command.Subcommand.Binding<Root> where B.Root == Root {
            binding
        }

        /// Allows `if`/`else` branches in the builder.
        public static func buildEither(
            first: [any Command.Subcommand.Binding<Root>]
        ) -> [any Command.Subcommand.Binding<Root>] {
            first
        }

        /// Allows `if`/`else` branches in the builder.
        public static func buildEither(
            second: [any Command.Subcommand.Binding<Root>]
        ) -> [any Command.Subcommand.Binding<Root>] {
            second
        }

        /// Allows `if` without `else` in the builder.
        public static func buildOptional(
            _ component: [any Command.Subcommand.Binding<Root>]?
        ) -> [any Command.Subcommand.Binding<Root>] {
            component ?? []
        }

        /// Allows array-of-bindings literals in the builder.
        public static func buildArray(
            _ components: [[any Command.Subcommand.Binding<Root>]]
        ) -> [any Command.Subcommand.Binding<Root>] {
            components.flatMap(\.self)
        }
    }
}
// swiftlint:enable no_any_protocol_existential
