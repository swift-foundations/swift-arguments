extension Swift.String: Argument.Codable {

    @inlinable
    public init?(argument: String) {
        self = argument
    }

    @inlinable
    public var argumentDescription: String {
        self
    }
}
