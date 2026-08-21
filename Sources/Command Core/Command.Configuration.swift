extension Command {

    public struct Configuration: Sendable, Hashable, Equatable {

        public let name: String

        public let abstract: String

        public let discussion: String

        public let version: String

        public let aliases: [String]

        @inlinable
        public init(
            name: String,
            abstract: String = "",
            discussion: String = "",
            version: String = "",
            aliases: [String] = []
        ) {
            self.name = name
            self.abstract = abstract
            self.discussion = discussion
            self.version = version
            self.aliases = aliases
        }
    }
}
