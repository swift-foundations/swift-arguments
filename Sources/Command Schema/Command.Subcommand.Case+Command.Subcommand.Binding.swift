extension Command.Subcommand.Case: Command.Subcommand.Binding {

    @inlinable
    public func parse(subArgv: [String]) throws(Command.Error) -> Root {
        let parsed = try Command.parse(Sub.self, from: subArgv, initial: initial())
        return map(parsed)
    }

    @inlinable
    public func appendHelp(to buffer: inout String, fullCommandName: String) {
        let configuration = Command.Configuration(
            name: fullCommandName,
            abstract: Sub.configuration.abstract,
            discussion: Sub.configuration.discussion,
            version: Sub.configuration.version,
            aliases: Sub.configuration.aliases
        )
        var visitor = Command.Subcommand.Help.Visitor<Sub>(configuration: configuration)
        Sub.schema.accept(&visitor)
        buffer += visitor.render()
    }
}
