// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-arguments open source project
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp and the swift-arguments project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Command_Namespace
public import Command_Core
public import Command_Schema
public import Command_Help
public import Process

extension Command {
    /// Parses argv, runs the conforming command, renders any error
    /// diagnostic, and exits the process with the canonical exit code.
    ///
    /// `Command.main(_:initial:arguments:)` is the convenience runner
    /// that consumers wire up at their `@main`-decorated entry point:
    ///
    /// ```swift
    /// @main
    /// struct App {
    ///     static func main() async {
    ///         await Command.main(MyCmd.self, initial: MyCmd())
    ///     }
    /// }
    /// ```
    ///
    /// The runner reduces a typical consumer entry point from ~25 lines
    /// (parse → catch error cases → render → exit) to three lines.
    ///
    /// ## Flow
    ///
    /// 1. Read `arguments` if supplied, else read `Swift.CommandLine.arguments`
    ///    and drop the executable name (argv[0]).
    /// 2. Call ``Command/parse(_:from:initial:)`` to produce a
    ///    populated root instance.
    /// 3. Call ``Command/Protocol/run()`` on the parsed root.
    /// 4. On success, exit with code 0.
    /// 5. On ``Command/Error``:
    ///    - Render the diagnostic via
    ///      ``Command/Diagnostic/message(for:)``.
    ///    - For ``Command/Error/helpRequested`` specifically, render
    ///      help text via ``Command/Help`` against the root schema.
    ///    - Map to the canonical exit code via
    ///      ``Command/Diagnostic/exitCode(for:)``.
    ///    - Exit with the mapped code.
    /// 6. On any other error (the conforming command's narrowed
    ///    ``Command/Protocol/Failure`` if non-default), render the
    ///    raw description and exit with code 1.
    ///
    /// ## Stderr handling — v1 limitation
    ///
    /// Diagnostics emit via `Swift.print(_:)` to stdout in v1. The
    /// ecosystem currently has no Foundation-free stderr write surface;
    /// adding one is a separate arc per the swift-arguments design doc
    /// v1.0.16. Real Unix tools route diagnostics to stderr — a v2
    /// follow-up will fix this once swift-io or swift-console grows a
    /// proper stderr write. Consumer apps that need strict
    /// stdout/stderr separation today should write their own runner
    /// composing ``Command/parse(_:from:initial:)`` and
    /// ``Command/Diagnostic``.
    ///
    /// - Parameters:
    ///   - commandType: The conforming command type.
    ///   - initial: A seed instance carrying default field values; the
    ///     parser only writes the fields named in argv, so unwritten
    ///     fields retain their `initial` values.
    ///   - arguments: Optional explicit argv. When `nil` (the default),
    ///     reads `Swift.CommandLine.arguments` and drops argv[0]
    ///     (executable name). Pass an explicit list for testing or for
    ///     consumers that pre-process argv.
    /// - Returns: Never — the process is terminated by
    ///   ``Process/exit(_:)``.
    public static func main<C: Command.`Protocol`>(
        _ commandType: C.Type,
        initial: C,
        arguments: [Swift.String]? = nil
    ) async -> Never {
        let argv: [Swift.String]
        if let arguments {
            argv = arguments
        } else {
            // Skip argv[0] (executable name). Swift.CommandLine.arguments
            // includes it by Unix convention; the parser expects the
            // argv-without-executable shape.
            let raw = Swift.CommandLine.arguments
            argv = raw.isEmpty ? raw : Array(raw.dropFirst())
        }

        do {
            var root = try Command.parse(commandType, from: argv, initial: initial)
            do throws(C.Failure) {
                try await root.run()
            } catch {
                // Narrowed C.Failure — render via Swift's String(describing:)
                // since this path bypasses Command.Error. Consumers
                // narrowing Failure can wrap their own diagnostics inside
                // run(); the runner stays generic.
                print("Error: \(Swift.String(describing: error))")
                Process.exit(1)
            }
            Process.exit(0)
        } catch let error as Command.Error {
            // Help is the only diagnostic path that renders the full
            // help text. The parse-time .helpRequested error carries no
            // pre-rendered text (vs. .helpRequestedForSubcommand which
            // does); the runner consults the Help serializer for the
            // root-command rendering.
            if case .helpRequested = error {
                var helpText = ""
                Command.Help<C>().serialize(C.schema, into: &helpText)
                print(helpText, terminator: "")
            } else {
                print(Command.Diagnostic.message(for: error))
            }
            Process.exit(Command.Diagnostic.exitCode(for: error))
        } catch {
            print("Error: \(Swift.String(describing: error))")
            Process.exit(1)
        }
    }
}
