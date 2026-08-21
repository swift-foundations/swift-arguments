extension Command {

    public struct Exit: Sendable, Hashable, Equatable {

        public let code: Int32

        @inlinable
        public init(code: Int32) {
            self.code = code
        }
    }
}

extension Command.Exit {

    public static let success: Command.Exit = .init(code: 0)

    public static let failure: Command.Exit = .init(code: 1)
}
