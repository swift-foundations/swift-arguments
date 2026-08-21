extension Command.Flag.Enumerable: Command.Schema.Node {

    public typealias Root = Command.Flag<Root>.BoundRoot

    @inlinable
    public func accept<Visitor: Command.Schema.Visitor>(
        _ visitor: inout Visitor
    ) throws(Visitor.Failure) where Visitor.Root == Command.Flag<Root>.BoundRoot {
        try visitor.visit(flagEnumerable: self)
    }
}
