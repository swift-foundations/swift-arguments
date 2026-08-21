extension Command.Subcommand {

    public protocol Binding<Root>: Sendable {

        associatedtype Root: Sendable

        var name: String { get }

        var aliases: [String] { get }

        var visibility: Argument.Visibility { get }

        var help: Argument.Help { get }

        var isDefault: Bool { get }

        func parse(subArgv: [String]) throws(Command.Error) -> Root

        func appendHelp(to buffer: inout String, fullCommandName: String)
    }
}
