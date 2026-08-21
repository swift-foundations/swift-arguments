import Testing

@testable import Command_Test_Support

extension Command {
    @Suite
    struct `Optional Argument` {

        @Test
        func `Both options absent: retain nil defaults`() throws(Command.Error) {
            let parsed = try Command.parse(
                OptionalSchema.self,
                from: [],
                initial: OptionalSchema()
            )
            #expect(parsed == OptionalSchema(label: nil, count: nil))
        }

        @Test
        func `--label populates Optional<String> to .some`() throws(Command.Error) {
            let parsed = try Command.parse(
                OptionalSchema.self,
                from: ["--label", "hello"],
                initial: OptionalSchema()
            )
            #expect(parsed == OptionalSchema(label: "hello", count: nil))
        }

        @Test
        func `--count populates Optional<Int> to .some`() throws(Command.Error) {
            let parsed = try Command.parse(
                OptionalSchema.self,
                from: ["--count", "42"],
                initial: OptionalSchema()
            )
            #expect(parsed == OptionalSchema(label: nil, count: 42))
        }

        @Test
        func `Both options present`() throws(Command.Error) {
            let parsed = try Command.parse(
                OptionalSchema.self,
                from: ["--label", "x", "--count", "7"],
                initial: OptionalSchema()
            )
            #expect(parsed == OptionalSchema(label: "x", count: 7))
        }

        @Test
        func `--label= empty argv produces .some("")`() throws(Command.Error) {

            let parsed = try Command.parse(
                OptionalSchema.self,
                from: ["--label", ""],
                initial: OptionalSchema()
            )
            #expect(parsed == OptionalSchema(label: "", count: nil))
        }

        @Test
        func `Invalid Int argv surfaces .invalidValue`() {
            do throws(Command.Error) {
                _ = try Command.parse(
                    OptionalSchema.self,
                    from: ["--count", "not-num"],
                    initial: OptionalSchema()
                )
                Issue.record("Expected invalidValue, parse succeeded")
            } catch {
                switch error {
                case .invalidValue:
                    break

                default:
                    Issue.record("Expected invalidValue, got \(error)")
                }
            }
        }

        @Test
        func `--count=value form populates Optional<Int>`() throws(Command.Error) {
            let parsed = try Command.parse(
                OptionalSchema.self,
                from: ["--count=99"],
                initial: OptionalSchema()
            )
            #expect(parsed == OptionalSchema(label: nil, count: 99))
        }
    }
}
