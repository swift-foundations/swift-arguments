extension Swift.Optional: Argument.Serializable where Wrapped: Argument.Serializable {

    @inlinable
    public var argumentDescription: String {
        switch self {
        case .some(let value):
            return value.argumentDescription

        case .none:
            return ""
        }
    }
}
