extension Command.Flag {

    public struct Enumerable<E: Argument.Flag.Enumerable>: Sendable
    where Root: Sendable {

        public let keyPath: any WritableKeyPath<Root, E> & Sendable

        public let visibility: Argument.Visibility

        public let help: Argument.Help

        @inlinable
        public init(
            _ keyPath: any WritableKeyPath<Root, E> & Sendable,
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init()
        ) {
            self.keyPath = keyPath
            self.visibility = visibility
            self.help = help
        }
    }
}
