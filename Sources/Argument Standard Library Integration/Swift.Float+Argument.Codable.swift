extension Swift.Float: Argument.Codable {

    @inlinable
    public init?(argument: String) {
        self.init(argument)
    }

    @inlinable
    public var argumentDescription: String {
        String(self)
    }
}
