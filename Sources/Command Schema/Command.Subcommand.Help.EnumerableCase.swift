extension Command.Subcommand.Help {

    @usableFromInline
    internal struct EnumerableCase: Sendable {

        @usableFromInline let name: String

        @usableFromInline let help: Argument.Help

        @usableFromInline
        internal init(name: String, help: Argument.Help) {
            self.name = name
            self.help = help
        }
    }
}
