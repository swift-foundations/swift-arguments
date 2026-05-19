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

extension Command.Schema {
    /// A single argument-schema node bound to a Root field.
    ///
    /// `Command.Schema.Node<Root>` is the L3 binding-aware analogue of
    /// L1's ``Argument/Schema/Node``. Conformers describe one argument
    /// declaration AND know how to write parsed values into a `Root`
    /// value via a `WritableKeyPath`.
    ///
    /// ## Conformers
    ///
    /// - ``Command/Positional`` — writes one parsed value to a Root field.
    /// - ``Command/Option`` — writes one parsed value from a named option.
    /// - ``Command/Flag`` — writes `true` to a Bool Root field on
    ///   presence of the flag.
    ///
    /// Per [API-IMPL-005], one conformer per file.
    public protocol Node<Root>: Sendable {
        /// The Root command struct whose fields this node writes to.
        associatedtype Root: Sendable

        /// Dispatches this node to the visitor's matching `visit(...)`
        /// method, recovering the static value type at the call site.
        ///
        /// - Parameter visitor: The visitor receiving the typed dispatch.
        /// - Throws: Any error the visitor surfaces (`V.Failure`).
        func accept<V: Command.Schema.Visitor>(_ visitor: inout V) throws(V.Failure) where V.Root == Root
    }
}
