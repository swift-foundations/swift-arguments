extension Command {

    public protocol `Protocol`: Sendable {

        associatedtype Failure: Swift.Error = Command.Error

        static var configuration: Command.Configuration { get }

        static var schema: Command.Schema.Definition<Self> { get }

        mutating func validate() throws(Command.Error)

        mutating func run() async throws(Failure)
    }
}
