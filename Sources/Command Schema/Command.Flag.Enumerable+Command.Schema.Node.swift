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

extension Command.Flag.Enumerable: Command.Schema.Node {
    /// The Schema.Node associated-type binding. References
    /// ``Command/Flag/BoundRoot`` so Swift can match the outer
    /// `Command.Flag<Root>`'s `Root` parameter without tripping the
    /// circular-typealias detection that would fire if we wrote
    /// `typealias Root = Root` directly.
    public typealias Root = Command.Flag<Root>.BoundRoot

    /// Dispatches this enumerable-flag binding to the visitor's
    /// `visit(flagEnumerable:)` method, recovering the static enum type
    /// `E` at the call site.
    @inlinable
    public func accept<Visitor: Command.Schema.Visitor>(
        _ visitor: inout Visitor
    ) throws(Visitor.Failure) where Visitor.Root == Command.Flag<Root>.BoundRoot {
        try visitor.visit(flagEnumerable: self)
    }
}
