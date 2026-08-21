extension Command {

    public struct Context: Sendable, Hashable, Equatable {

        public let executableName: String

        public let remainingArguments: [String]

        @inlinable
        public init(
            executableName: String = "",
            remainingArguments: [String] = []
        ) {
            self.executableName = executableName
            self.remainingArguments = remainingArguments
        }
    }
}
