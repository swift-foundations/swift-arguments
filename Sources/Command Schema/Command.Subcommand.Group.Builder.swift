extension Command.Subcommand.Group {

    @resultBuilder
    public enum Builder {

        public static func buildBlock(
            _ bindings: any Command.Subcommand.Binding<Root>...
        ) -> [any Command.Subcommand.Binding<Root>] {
            bindings
        }

        public static func buildExpression<B: Command.Subcommand.Binding>(
            _ binding: B
        ) -> any Command.Subcommand.Binding<Root> where B.Root == Root {
            binding
        }

        public static func buildEither(
            first: [any Command.Subcommand.Binding<Root>]
        ) -> [any Command.Subcommand.Binding<Root>] {
            first
        }

        public static func buildEither(
            second: [any Command.Subcommand.Binding<Root>]
        ) -> [any Command.Subcommand.Binding<Root>] {
            second
        }

        public static func buildOptional(
            _ component: [any Command.Subcommand.Binding<Root>]?
        ) -> [any Command.Subcommand.Binding<Root>] {
            component ?? []
        }

        public static func buildArray(
            _ components: [[any Command.Subcommand.Binding<Root>]]
        ) -> [any Command.Subcommand.Binding<Root>] {
            components.flatMap(\.self)
        }
    }
}
