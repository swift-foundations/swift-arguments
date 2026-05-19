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

extension Command.OptionGroup: Command.Schema.Node {
    /// Dispatches this option-group declaration to the visitor's
    /// `visit(optionGroup:)` method, recovering the static fragment-type
    /// `G` at the call site.
    @inlinable
    public func accept<Visitor: Command.Schema.Visitor>(
        _ visitor: inout Visitor
    ) throws(Visitor.Failure) where Visitor.Root == Root {
        try visitor.visit(optionGroup: self)
    }
}
