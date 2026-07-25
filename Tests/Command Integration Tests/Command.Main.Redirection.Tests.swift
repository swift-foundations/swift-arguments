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

import Process
import Testing

@testable import Command_Test_Support

// MARK: - Helper-process harness

/// Spawns the `command-runner-helper` executable with its stdout on a
/// **pipe** and returns the captured bytes plus exit status.
///
/// ## Why a pipe, and why a child process at all
///
/// `Command.main(_:initial:)` returns `Never` — it terminates the
/// process — so nothing about its termination behaviour is observable
/// in-process. It has to be run as a child and captured.
///
/// The capture MUST NOT be a terminal, and this is the whole point of
/// the suite rather than an implementation detail. C stdio picks its
/// buffering mode from what stdout *is*:
///
/// - **TTY → line-buffered.** Every `print` ending in a newline flushes
///   immediately, so output survives even a termination path that skips
///   the flush. A test run on a terminal therefore passes whether or
///   not the bug is present — it proves nothing.
/// - **Pipe or regular file → block-buffered.** Output accumulates in
///   the stdio buffer until it fills or the stream is flushed at normal
///   exit. A termination path that skips the flush (`_exit(2)`) discards
///   it, and the process exits with a correct status having written
///   zero bytes.
///
/// `Process.Stream.pipe` routes the child's stdout through
/// `pipe(2)`/`posix_spawn` file actions, so `isatty(1)` is false in the
/// child and its stdio is block-buffered. That is the failing condition,
/// forced deterministically and with no dependence on the environment
/// the test itself happens to run under.
private enum HelperProcess {}

extension HelperProcess {
    /// Candidate locations for the built helper binary.
    ///
    /// `#filePath` is `<package>/Tests/Command Integration Tests/<this
    /// file>`; three path components up is the package root. Both the
    /// `.build/debug` symlink and the triple-qualified directory are
    /// tried, since which one exists depends on the build driver.
    static func candidatePaths(filePath: StaticString = #filePath) -> [Swift.String] {
        let name = "command-runner-helper"
        var root = filePath.description
        for _ in 0..<3 {
            guard let slash = root.lastIndex(of: "/") else { break }
            root = Swift.String(root[..<slash])
        }
        return [
            "\(root)/.build/debug/\(name)",
            "\(root)/.build/arm64-apple-macosx/debug/\(name)",
            "\(root)/.build/x86_64-apple-macosx/debug/\(name)",
        ]
    }

    /// Runs the helper with `arguments`, stdout and stderr on pipes.
    ///
    /// - Returns: the captured output, or `nil` if no candidate path
    ///   produced a runnable binary.
    static func run(_ arguments: [Swift.String]) -> Process.Output? {
        for path in candidatePaths() {
            let configuration = Process.Spawn.Configuration(
                executable: path,
                arguments: arguments,
                stdout: .pipe,
                stderr: .pipe
            )
            do throws(Process.Error) {
                return try Process.Spawn.run(configuration)
            } catch {
                // A candidate path that does not exist fails at spawn
                // time (ENOENT). That is expected while probing the
                // build-layout candidates, so move to the next one. If
                // every candidate fails, the `nil` return surfaces as a
                // `#require` failure at the call site rather than a
                // silently-passing test.
                continue
            }
        }
        return nil
    }

    /// The child's captured stdout decoded as UTF-8.
    static func stdoutText(_ output: Process.Output) -> Swift.String {
        Swift.String(decoding: output.stdout ?? [], as: UTF8.self)
    }
}

// MARK: - Tests

@Suite
struct `Command.main redirected-output Tests` {

    // Why these tests exist:
    //
    // `Command.main` rendered its output with `print(_:)` and then
    // terminated via `Process.exit(_:)`, which is `_exit(2)` semantics —
    // it bypasses stdio flushing. Exit codes were correct and output on
    // a terminal looked correct, but every byte was discarded the moment
    // stdout was redirected to a pipe or a file. Measured before the
    // fix, capturing to a file:
    //
    //   argv            exit   bytes
    //   <phrase>        0      0
    //   --help          0      0
    //   --bogusflag     64     0
    //   (none)          64     0
    //
    // The same four invocations on a PTY produced 31 / 193 / 38 / 46
    // bytes respectively — which is exactly why every test below
    // captures through a pipe. On a TTY they would all pass with the
    // bug fully present.
    //
    // `--help` is the load-bearing case: it is rendered entirely inside
    // swift-arguments and never reaches consumer code, so it isolates
    // the fault to this package.

    @Test
    func `Successful run writes its output when stdout is a pipe`() throws {
        let output = try #require(
            HelperProcess.run(["hello"]),
            "helper executable not found — is the package built?"
        )
        #expect(output.status == .exited(code: 0))
        #expect(HelperProcess.stdoutText(output).contains("HELPER-BEGIN hello HELPER-END"))
    }

    @Test
    func `Help output is not discarded when stdout is a pipe`() throws {
        let output = try #require(HelperProcess.run(["--help"]))
        #expect(output.status == .exited(code: 0))
        let text = HelperProcess.stdoutText(output)
        #expect(!text.isEmpty)
        #expect(text.contains("USAGE:"))
        #expect(text.contains("command-runner-helper"))
    }

    @Test
    func `Unknown-option diagnostic is not discarded when stdout is a pipe`() throws {
        let output = try #require(HelperProcess.run(["--bogusflag"]))
        #expect(output.status == .exited(code: 64))
        #expect(HelperProcess.stdoutText(output).contains("--bogusflag"))
    }

    @Test
    func `Missing-argument diagnostic is not discarded when stdout is a pipe`() throws {
        let output = try #require(HelperProcess.run([]))
        #expect(output.status == .exited(code: 64))
        #expect(HelperProcess.stdoutText(output).contains("phrase"))
    }

    @Test
    func `Every exit path writes a non-empty stdout when redirected`() throws {
        // Guards the exit paths as a family rather than one at a time:
        // a future exit site added to `Command.main` that reaches for
        // the non-flushing call fails here even if no case above names
        // it. The byte-count assertion is the invariant that the
        // original defect violated on all four paths at once.
        for arguments in [["hello"], ["--help"], ["--bogusflag"], []] {
            let output = try #require(
                HelperProcess.run(arguments),
                "helper executable not found for argv \(arguments)"
            )
            #expect(
                !(output.stdout ?? []).isEmpty,
                "argv \(arguments) wrote zero bytes to a piped stdout"
            )
        }
    }
}
