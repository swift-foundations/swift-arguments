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

extension Command {
    /// The L3 sum-type subcommand-dispatch namespace.
    ///
    /// `Command.Subcommand` is the namespace anchor for the L3
    /// binding-aware analogue of L1's ``Argument/Subcommand`` declaration.
    /// Per the design doc §2.3, subcommand dispatch semantically maps to
    /// `Parser.OneOf` over a sum-type — this namespace hosts the L3
    /// realization of that pattern with KeyPath-equivalent case mapping.
    ///
    /// ## Members
    ///
    /// - ``Command/Subcommand/Binding`` — the existential carrier
    ///   protocol for one subcommand declaration. Bindings hold the
    ///   subcommand name + sub-parse + Root case-mapping behavior.
    /// - ``Command/Subcommand/Case`` — the concrete binding type:
    ///   `Case<Root, Sub>` pairs a subcommand name with a Sub Command
    ///   type and a `(Sub) -> Root` case-wrapping closure.
    /// - ``Command/Subcommand/Group`` — a `Parser.OneOf`-shaped host
    ///   for a heterogeneous list of ``Binding``s, conforming to
    ///   ``Command/Schema/Node`` so it composes with the existing
    ///   schema builder grammar.
    /// - ``Command/Subcommand/Help`` — Schema-internal help-rendering
    ///   visitor used by ``Case/appendHelp(to:fullCommandName:)``.
    ///
    /// Per [API-NAME-001], the dotted nesting reads as
    /// `Command.Subcommand.Case("clone", ...)` — no compound names.
    public enum Subcommand {}
}
