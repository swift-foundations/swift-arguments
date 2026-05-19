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

extension Command.Positional.Many: Command.Schema.Node {
    /// Dispatches this array-positional binding to the visitor's
    /// `visit(positionalMany:)` method, recovering the static value type
    /// `V` at the call site.
    @inlinable
    public func accept<Visitor: Command.Schema.Visitor>(
        _ visitor: inout Visitor
    ) throws(Visitor.Failure) where Visitor.Root == Root {
        try visitor.visit(positionalMany: self)
    }
}
