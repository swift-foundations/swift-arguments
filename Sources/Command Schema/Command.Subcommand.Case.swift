extension Command.Subcommand {

    public struct Case<Root, Sub>: Sendable
    where Root: Sendable, Sub: Command.`Protocol` {

        public let name: String

        public let aliases: [String]

        public let visibility: Argument.Visibility

        public let help: Argument.Help

        public let isDefault: Bool

        public let initial: @Sendable () -> Sub

        public let map: @Sendable (Sub) -> Root

        @inlinable
        public init(
            _ name: String,
            aliases: [String] = [],
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init(),
            isDefault: Bool = false,
            initial: @escaping @Sendable () -> Sub,
            map: @escaping @Sendable (Sub) -> Root
        ) {
            self.name = name
            self.aliases = aliases
            self.visibility = visibility
            self.help = help
            self.isDefault = isDefault
            self.initial = initial
            self.map = map
        }
    }
}

extension Command.Subcommand.Case {

    public var `default`: Self {
        Self(
            name,
            aliases: aliases,
            visibility: visibility,
            help: help,
            isDefault: true,
            initial: initial,
            map: map
        )
    }
}
