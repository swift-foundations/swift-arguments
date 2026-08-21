extension Command.Schema {

    public protocol Visitor<Root> {

        associatedtype Root: Sendable

        associatedtype Failure: Swift.Error = Never

        mutating func visit<V: Sendable & Equatable>(
            positional: Command.Positional<Root, V>
        ) throws(Failure)

        mutating func visit<V: Sendable & Equatable>(
            positionalMany: Command.Positional<Root, V>.Many
        ) throws(Failure)

        mutating func visit<V: Sendable & Equatable>(
            option: Command.Option<Root, V>
        ) throws(Failure)

        mutating func visit<V: Sendable & Equatable>(
            optionMany: Command.Option<Root, V>.Many
        ) throws(Failure)

        mutating func visit(flag: Command.Flag<Root>) throws(Failure)

        mutating func visit(flagCount: Command.Flag<Root>.Count) throws(Failure)

        mutating func visit(flagInverted: Command.Flag<Root>.Inverted) throws(Failure)

        mutating func visit<E: Argument.Flag.Enumerable>(
            flagEnumerable: Command.Flag<Root>.Enumerable<E>
        ) throws(Failure)

        mutating func visit(subcommandGroup: Command.Subcommand.Group<Root>) throws(Failure)

        mutating func visit<G: Sendable & Equatable>(
            optionGroup: Command.OptionGroup<Root, G>
        ) throws(Failure)
    }
}
