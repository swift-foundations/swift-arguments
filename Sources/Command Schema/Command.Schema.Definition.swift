extension Command.Schema {

    public struct Definition<Root: Sendable>: Sendable {

        public let nodes: [any Command.Schema.Node<Root>]

        @inlinable
        public init(nodes: [any Command.Schema.Node<Root>]) {
            self.nodes = nodes
        }

        @inlinable
        public init(@Command.Builder<Root> _ build: () -> [any Command.Schema.Node<Root>]) {
            self.nodes = build()
        }

        @inlinable
        public func accept<Visitor: Command.Schema.Visitor>(
            _ visitor: inout Visitor
        ) throws(Visitor.Failure) where Visitor.Root == Root {
            for node in nodes {
                try node.accept(&visitor)
            }
        }
    }
}
