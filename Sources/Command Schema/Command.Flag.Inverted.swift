extension Command.Flag {

    public struct Inverted: Sendable where Root: Sendable {

        public let keyPath: any WritableKeyPath<Root, Bool> & Sendable

        public let base: Argument.Name.Long

        public let inversion: Inversion

        public let visibility: Argument.Visibility

        public let help: Argument.Help

        @inlinable
        public init(
            _ keyPath: any WritableKeyPath<Root, Bool> & Sendable,
            base: Argument.Name.Long,
            inversion: Inversion = .prefixedNo,
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init()
        ) {
            self.keyPath = keyPath
            self.base = base
            self.inversion = inversion
            self.visibility = visibility
            self.help = help
        }
    }
}
