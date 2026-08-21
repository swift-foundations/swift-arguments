internal import Environment

extension Argument.Environment {

    public static func withOverlay<R, E: Swift.Error>(
        _ values: [Swift.String: Swift.String],
        perform body: () throws(E) -> R
    ) throws(E) -> R {
        try Environment.withOverlay(values, perform: body)
    }
}
