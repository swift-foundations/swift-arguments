extension Command {

    @resultBuilder
    public enum Builder<Root: Sendable> {

        public static func buildBlock(
            _ nodes: any Command.Schema.Node<Root>...
        ) -> [any Command.Schema.Node<Root>] {
            nodes
        }

        public static func buildExpression<N: Command.Schema.Node>(
            _ node: N
        ) -> any Command.Schema.Node<Root> where N.Root == Root {
            node
        }

        public static func buildEither(
            first: [any Command.Schema.Node<Root>]
        ) -> [any Command.Schema.Node<Root>] {
            first
        }

        public static func buildEither(
            second: [any Command.Schema.Node<Root>]
        ) -> [any Command.Schema.Node<Root>] {
            second
        }

        public static func buildOptional(
            _ component: [any Command.Schema.Node<Root>]?
        ) -> [any Command.Schema.Node<Root>] {
            component ?? []
        }

        public static func buildArray(
            _ components: [[any Command.Schema.Node<Root>]]
        ) -> [any Command.Schema.Node<Root>] {
            components.flatMap(\.self)
        }
    }
}
