import Command_Core
import Command_Help
public import Command_Primitive
public import Command_Schema
import Process

extension Command {

    public static func main<C: `Protocol`>(
        _ commandType: C.Type,
        initial: C,
        arguments: [Swift.String]? = nil
    ) async -> Never {
        let argv: [Swift.String]
        if let arguments {
            argv = arguments
        } else {

            let raw = Swift.CommandLine.arguments
            argv = raw.isEmpty ? raw : Array(raw.dropFirst())
        }

        do {
            var root = try Self.parse(commandType, from: argv, initial: initial)
            do throws(C.Failure) {
                try await root.run()
            } catch {

                print("Error: \(Swift.String(describing: error))")
                Process.Exit.normal(1)
            }
            Process.Exit.normal(0)
        } catch {

            if case .helpRequested = error {
                var helpText = ""
                Self.Help<C>().serialize(C.schema, into: &helpText)
                print(helpText, terminator: "")
            } else {
                print(Self.Diagnostic.message(for: error))
            }
            Process.Exit.normal(Self.Diagnostic.exitCode(for: error))
        }
    }
}
