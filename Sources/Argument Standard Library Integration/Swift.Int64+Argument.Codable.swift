extension Swift.Int64: Argument.Codable {

    @inlinable
    public init?(argument: String) {
        self.init(argument)
    }

    @inlinable
    public var argumentDescription: String {
        String(self)
    }
}
