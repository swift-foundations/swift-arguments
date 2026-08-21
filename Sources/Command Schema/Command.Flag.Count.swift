extension Command.Flag {

    public struct Count: Sendable where Root: Sendable {

        public let keyPath: any WritableKeyPath<Root, Int> & Sendable

        public let declaration: Argument.Flag

        @inlinable
        public init(
            _ keyPath: any WritableKeyPath<Root, Int> & Sendable,
            name: Argument.Name,
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init()
        ) {
            self.keyPath = keyPath
            self.declaration = Argument.Flag(
                name: name,
                arity: .count,
                visibility: visibility,
                help: help
            )
        }
    }
}
