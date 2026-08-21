internal import Environment

extension Command.Schema.ParseVisitor {

    @usableFromInline
    internal static func readEnvironmentVariable(_ name: Swift.String) -> Swift.String? {
        Environment.task.read(name)
    }
}
