extension Command {

    public struct OptionGroup<Root, G>: Sendable
    where Root: Sendable, G: Sendable & Equatable {

        public let keyPath: any WritableKeyPath<Root, G> & Sendable

        public let schema: Command.Schema.Definition<G>

        public let visibility: Argument.Visibility

        @inlinable
        public init(
            _ keyPath: any WritableKeyPath<Root, G> & Sendable,
            schema: Command.Schema.Definition<G>,
            visibility: Argument.Visibility = .visible
        ) {
            self.keyPath = keyPath
            self.schema = schema
            self.visibility = visibility
        }
    }
}
