extension Command {

    public struct Flag<Root>: Sendable where Root: Sendable {

        public typealias BoundRoot = Root

        public let keyPath: any WritableKeyPath<Root, Bool> & Sendable

        public let declaration: Argument.Flag

        @inlinable
        public init(
            _ keyPath: any WritableKeyPath<Root, Bool> & Sendable,
            name: Argument.Name,
            arity: Argument.Arity = .atMost(1),
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init()
        ) {
            self.keyPath = keyPath
            self.declaration = Argument.Flag(
                name: name,
                arity: arity,
                visibility: visibility,
                help: help
            )
        }
    }
}
