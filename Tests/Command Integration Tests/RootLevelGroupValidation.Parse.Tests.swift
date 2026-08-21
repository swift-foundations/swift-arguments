import Testing

@testable import Command_Test_Support

extension Command {
    @Suite
    struct `Root Level Group Validation` {

        @Test
        func `Root-level flag combined with Subcommand.Group throws .validationFailed`() {
            do throws(Command.Error) {
                _ = try Command.parse(
                    RootFlagWithGroup.self,
                    from: ["--verbose", "child"],
                    initial: RootFlagWithGroup()
                )
                Issue.record("Expected .validationFailed, parse succeeded")
            } catch {
                switch error {
                case .validationFailed:
                    break

                default:
                    Issue.record("Expected .validationFailed, got \(error)")
                }
            }
        }

        @Test
        func `Rejection fires even when argv omits the root-level flag`() {

            do throws(Command.Error) {
                _ = try Command.parse(
                    RootFlagWithGroup.self,
                    from: ["child"],
                    initial: RootFlagWithGroup()
                )
                Issue.record("Expected .validationFailed, parse succeeded")
            } catch {
                switch error {
                case .validationFailed:
                    break

                default:
                    Issue.record("Expected .validationFailed, got \(error)")
                }
            }
        }
    }
}
