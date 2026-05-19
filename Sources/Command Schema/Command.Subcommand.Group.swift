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
// reason: subcommand-binding heterogeneity is load-bearing — each
// binding carries a distinct `Sub` generic; no protocol-with-AT shape
// collapses the heterogeneous list. The Visitor's double-dispatch via
// `Schema.Node.accept(_:)` recovers the parent `Root` static type at
// the call site.
extension Command.Subcommand {
    /// A grouped set of sum-type subcommand bindings.
    ///
    /// `Command.Subcommand.Group<Root>` is the `Parser.OneOf`-shaped host
    /// for a list of subcommand bindings whose sub-command types differ.
    /// Per the design doc §2.3, subcommand dispatch semantically maps to
    /// `Parser.OneOf` over a sum-type — this is the L3 binding-aware
    /// realization of that pattern.
    ///
    /// The Group itself conforms to ``Command/Schema/Node`` so it plugs
    /// into the existing ``Command/Schema/Definition`` builder grammar
    /// alongside positionals, options, and flags.
    ///
    /// ## Example
    ///
    /// ```swift
    /// enum Git: Command.`Protocol` {
    ///     case clone(Clone)
    ///     case status(Status)
    ///
    ///     static var schema: Command.Schema.Definition<Self> {
    ///         Command.Schema.Definition {
    ///             Command.Subcommand.Group {
    ///                 Command.Subcommand("clone", initial: Clone.init, map: Git.clone)
    ///                 Command.Subcommand("status", initial: Status.init, map: Git.status)
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    public struct Group<Root: Sendable>: Sendable {
        /// The subcommand bindings in declaration order.
        ///
        /// `[any Command.Subcommand.Binding<Root>]` is necessarily
        /// existential — each binding has a distinct `Sub` generic.
        public let bindings: [any Command.Subcommand.Binding<Root>]

        /// Creates a subcommand group from an ordered list of bindings.
        ///
        /// At most one binding may carry ``Command/Subcommand/Binding/isDefault``
        /// equal to `true`; passing a list with two-or-more default
        /// bindings triggers a `preconditionFailure` — the schema is
        /// malformed at the source level and the failure is a programmer
        /// error, not a runtime argv-dispatch failure.
        @inlinable
        public init(bindings: [any Command.Subcommand.Binding<Root>]) {
            Self.checkAtMostOneDefault(bindings)
            self.bindings = bindings
        }

        /// Creates a subcommand group from a `@Command.Subcommand.Group.Builder`
        /// closure.
        ///
        /// Enforces the at-most-one-default invariant; see
        /// ``init(bindings:)`` for the rationale.
        @inlinable
        public init(
            @Builder _ build: () -> [any Command.Subcommand.Binding<Root>]
        ) {
            let bindings = build()
            Self.checkAtMostOneDefault(bindings)
            self.bindings = bindings
        }

        /// Validates the at-most-one-default invariant.
        ///
        /// Factored into a static helper so both initializers share the
        /// check and the error message is uniform. Triggers a
        /// `preconditionFailure` when the invariant is violated — schema
        /// construction is a compile-time-shaped concern; runtime
        /// fallthrough to argv dispatch would mask a programmer error.
        @inlinable
        internal static func checkAtMostOneDefault(
            _ bindings: [any Command.Subcommand.Binding<Root>]
        ) {
            let defaults = bindings.filter(\.isDefault)
            guard defaults.count <= 1 else {
                let names = defaults.map(\.name).joined(separator: ", ")
                preconditionFailure(
                    "Command.Subcommand.Group declares more than one default subcommand: \(names). "
                        + "At most one Case may carry .default per Group."
                )
            }
        }
    }
}
// swiftlint:enable no_any_protocol_existential
