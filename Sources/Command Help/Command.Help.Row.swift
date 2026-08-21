extension Command {

    @usableFromInline
    internal enum HelpRow: Sendable {
        case positional(
            name: String,
            placeholder: String,
            help: Argument.Help,
            visibility: Argument.Visibility
        )

        case positionalMany(
            name: String,
            placeholder: String,
            help: Argument.Help,
            visibility: Argument.Visibility
        )
        case option(
            name: Argument.Name,
            placeholder: String,
            help: Argument.Help,
            visibility: Argument.Visibility
        )

        case optionMany(
            name: Argument.Name,
            placeholder: String,
            help: Argument.Help,
            visibility: Argument.Visibility
        )
        case flag(name: Argument.Name, help: Argument.Help, visibility: Argument.Visibility)

        case flagCount(name: Argument.Name, help: Argument.Help, visibility: Argument.Visibility)

        case flagInverted(
            trueName: String,
            falseName: String,
            help: Argument.Help,
            visibility: Argument.Visibility
        )

        case flagEnumerable(
            cases: [Command.HelpEnumerableCase],
            help: Argument.Help,
            visibility: Argument.Visibility
        )
        case subcommand(name: String, help: Argument.Help, visibility: Argument.Visibility)
    }
}
