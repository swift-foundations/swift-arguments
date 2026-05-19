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
    /// The schema namespace.
    ///
    /// `Command.Schema` owns the L3 binding-aware schema layer:
    ///
    /// - ``Command/Schema/Definition`` — the schema-as-data value carrying
    ///   an ordered list of KeyPath-bound schema nodes.
    /// - ``Command/Schema/Node`` — the L3 node protocol; conformers
    ///   describe one argument declaration AND know how to write parsed
    ///   values into a `Root` value via a `WritableKeyPath`.
    /// - ``Command/Schema/Visitor`` — the L3 visitor protocol; help-text
    ///   and completion-script emitters at L3 walk the schema via this
    ///   visitor type.
    ///
    /// ## Distinction from L1 `Argument.Schema`
    ///
    /// L1's ``Argument/Schema/Definition`` carries un-bound declarations
    /// (no `WritableKeyPath`). L3's ``Command/Schema/Definition``
    /// carries KeyPath-bound nodes — the type system enforces that every
    /// node writes to a typed field on the `Root` command struct. The
    /// two layers share the schema-as-data structural pattern but
    /// differ on whether the nodes know where their parsed values land.
    public enum Schema {}
}
