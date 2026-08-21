extension Command.Schema {

    public protocol Node<Root>: Sendable {

        associatedtype Root: Sendable

        func accept<V: Command.Schema.Visitor>(_ visitor: inout V) throws(V.Failure)
        where V.Root == Root
    }
}
