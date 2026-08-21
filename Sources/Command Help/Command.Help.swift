public import Serializer_Primitives

extension Command {

    public struct Help<Root: Command.`Protocol`>: Serializer.`Protocol` {

        public typealias Output = Command.Schema.Definition<Root>

        public typealias Buffer = Swift.String

        public typealias Failure = Never

        public typealias Body = Never

        @inlinable
        public init() {}

        @inlinable
        public borrowing func serialize(
            _ output: Command.Schema.Definition<Root>,
            into buffer: inout Swift.String
        ) {
            var visitor = Command.Help<Root>.Visitor(configuration: Root.configuration)
            output.accept(&visitor)
            buffer += visitor.render()
        }

        @inlinable
        public borrowing func serialize(
            _ output: Command.Schema.Definition<Root>,
            into buffer: inout Swift.String,
            initial: Root
        ) {
            var visitor = Command.Help<Root>.Visitor(
                configuration: Root.configuration,
                initial: initial
            )
            output.accept(&visitor)
            buffer += visitor.render()
        }
    }
}
