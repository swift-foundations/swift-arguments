import Testing

@testable import Command_Test_Support

extension Command {
    @Suite
    struct Transform {

        @Test
        func `Command.Positional + transform: parses non-Codable value`() throws(Command.Error) {
            let parsed = try Command.parse(
                TransformedPositional.self,
                from: ["https://example.com"],
                initial: TransformedPositional()
            )
            #expect(parsed.endpoint == TransformedHost(scheme: "https", host: "example.com"))
        }

        @Test
        func `Command.Positional + transform: throws .invalidValue on malformed input`() {
            #expect(throws: Command.Error.self) {
                _ = try Command.parse(
                    TransformedPositional.self,
                    from: ["malformed-no-separator"],
                    initial: TransformedPositional()
                )
            }
        }

        @Test
        func `Command.Option + transform: parses non-Codable value`() throws(Command.Error) {
            let parsed = try Command.parse(
                TransformedOption.self,
                from: ["--endpoint", "https://example.com"],
                initial: TransformedOption()
            )
            #expect(parsed.endpoint == TransformedHost(scheme: "https", host: "example.com"))
        }

        @Test
        func `Command.Option + transform: throws .invalidValue on malformed input`() {
            #expect(throws: Command.Error.self) {
                _ = try Command.parse(
                    TransformedOption.self,
                    from: ["--endpoint", "no-scheme-separator"],
                    initial: TransformedOption()
                )
            }
        }

        @Test
        func `Command.Positional.Many + transform: parses multiple non-Codable values`()
            throws(Command.Error)
        {
            let parsed = try Command.parse(
                TransformedPositionalMany.self,
                from: ["https://a.com", "http://b.org", "ftp://c.net"],
                initial: TransformedPositionalMany()
            )
            #expect(
                parsed.endpoints == [
                    TransformedHost(scheme: "https", host: "a.com"),
                    TransformedHost(scheme: "http", host: "b.org"),
                    TransformedHost(scheme: "ftp", host: "c.net"),
                ]
            )
        }

        @Test
        func `Command.Positional.Many + transform: empty argv → empty array`() throws(Command.Error)
        {
            let parsed = try Command.parse(
                TransformedPositionalMany.self,
                from: [],
                initial: TransformedPositionalMany()
            )
            #expect(parsed.endpoints == [])
        }

        @Test
        func `Command.Option.Many + transform: parses multiple non-Codable values`() throws(Command
            .Error)
        {
            let parsed = try Command.parse(
                TransformedOptionMany.self,
                from: [
                    "--endpoint", "https://a.com",
                    "--endpoint", "http://b.org",
                    "--endpoint", "ftp://c.net",
                ],
                initial: TransformedOptionMany()
            )
            #expect(
                parsed.endpoints == [
                    TransformedHost(scheme: "https", host: "a.com"),
                    TransformedHost(scheme: "http", host: "b.org"),
                    TransformedHost(scheme: "ftp", host: "c.net"),
                ]
            )
        }

        @Test
        func `Command.Option.Many + transform: zero occurrences → empty array`() throws(Command
            .Error)
        {
            let parsed = try Command.parse(
                TransformedOptionMany.self,
                from: [],
                initial: TransformedOptionMany()
            )
            #expect(parsed.endpoints == [])
        }
    }
}
