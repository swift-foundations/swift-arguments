extension Swift.Optional: Argument.Parseable where Wrapped: Argument.Parseable {

    @inlinable
    public init?(argument: String) {
        guard let wrapped = Wrapped(argument: argument) else {
            return nil
        }
        self = .some(wrapped)
    }
}
