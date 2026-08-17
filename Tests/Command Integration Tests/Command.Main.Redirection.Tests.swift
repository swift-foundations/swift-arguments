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

#if canImport(Darwin)
    import Darwin  // dladdr, Dl_info, getenv, access, X_OK
#elseif canImport(Glibc)
    import Glibc  // getenv, access, X_OK, readlink
#elseif canImport(WinSDK)
    import WinSDK  // GetModuleFileNameW, GetEnvironmentVariableW, GetFileAttributesW
#endif

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
    /// The name of the helper executable target.
    static let helperName = "command-runner-helper"

    /// The helper's candidate on-disk file names, most likely first.
    ///
    /// Windows carries executability in the extension, so `.exe` is the
    /// name to expect there — but SwiftPM has emitted the bare target
    /// name on Windows too, so both are tried rather than betting on
    /// one and reporting "not found" when the other is sitting there.
    #if os(Windows)
        static let helperFileNames = ["\(helperName).exe", helperName]
    #else
        static let helperFileNames = [helperName]
    #endif

    /// The directory separator the platform puts in its own image paths.
    ///
    /// Windows accepts `/` in a path it is *given*, but the paths this
    /// harness *reads back* — from `GetModuleFileNameW` — are spelled
    /// with `\`, and the ascent below works by trimming the image path
    /// it was handed.
    #if os(Windows)
        static let pathSeparator: Swift.Character = "\\"
    #else
        static let pathSeparator: Swift.Character = "/"
    #endif

    /// Environment variable that overrides the helper's location, so CI
    /// can point at a prebuilt binary without relying on any layout.
    static let helperOverride = "COMMAND_RUNNER_HELPER"

    /// Decodes a NUL-terminated `CChar` buffer via the pointer overload
    /// of `String.init(cString:)`.
    ///
    /// The `[CChar]` overload is deprecated in favour of
    /// `String(decoding:as:)`, which would mean truncating the NUL and
    /// rebinding to `UInt8` by hand. This encapsulates its own
    /// unsafety, so call sites must NOT mark it `unsafe`.
    static func string(fromNulTerminated buffer: [CChar]) -> Swift.String {
        unsafe buffer.withUnsafeBufferPointer { pointer in
            guard let baseAddress = pointer.baseAddress else { return "" }
            return unsafe Swift.String(cString: baseAddress)
        }
    }

    #if canImport(Darwin)
        /// Address-only marker identifying the image containing this code.
        ///
        /// Never called; only its address is taken.
        static let imageMarker: @convention(c) () -> Void = {}
    #endif

    /// The absolute path of the image containing this test code.
    ///
    /// The platform split is load-bearing, not incidental:
    ///
    /// - **Darwin** asks `dladdr` which image contains our own code.
    ///   Under `swift test` the *main executable* is the `xctest` tool
    ///   and the test binary is a **loaded bundle**, so any
    ///   main-executable query — `argv[0]`, `_NSGetExecutablePath` —
    ///   returns the runner and the search finds nothing.
    /// - **Linux** uses `/proc/self/exe`, because there is no bundle
    ///   indirection: the test binary *is* the main executable. And
    ///   `dladdr`/`Dl_info` are not exposed by the `Glibc` module at
    ///   all, so the Darwin form is unavailable here regardless.
    ///
    /// Anchoring to our own image also pins resolution to the current
    /// configuration's products directory, so it cannot pick up a
    /// stale sibling built under a different configuration.
    static func runningImagePath() -> Swift.String? {
        #if canImport(Darwin)
            var info = unsafe Dl_info()
            let address: UnsafeRawPointer = unsafe unsafeBitCast(
                Self.imageMarker,
                to: UnsafeRawPointer.self
            )
            guard unsafe dladdr(address, &info) != 0 else { return nil }
            guard let name = unsafe info.dli_fname else { return nil }
            return unsafe Swift.String(cString: name)
        #elseif canImport(Glibc)
            var buffer = [CChar](repeating: 0, count: 4096)
            let written = unsafe readlink("/proc/self/exe", &buffer, buffer.count - 1)
            guard written > 0 else { return nil }
            buffer[written] = 0
            return Self.string(fromNulTerminated: buffer)
        #elseif os(Windows)
            // There is no bundle indirection on Windows either: the test
            // binary is the main executable, so the module handle `nil`
            // names our own image. The buffer is sized for a long path
            // rather than `MAX_PATH`, because a package checkout nested
            // under a SwiftPM build directory routinely exceeds 260
            // characters and a short buffer would truncate silently.
            var buffer = [WCHAR](repeating: 0, count: 32768)
            let written = unsafe GetModuleFileNameW(nil, &buffer, DWORD(buffer.count))
            guard written > 0, written < DWORD(buffer.count) else { return nil }
            return Swift.String(decoding: buffer[..<Swift.Int(written)], as: UTF16.self)
        #else
            return nil
        #endif
    }

    /// Whether `path` names a file that can be spawned.
    ///
    /// Windows has no execute permission bit to consult: executability
    /// is carried by the `.exe` extension, which `helperFileName`
    /// already supplies. The meaningful question there is whether the
    /// candidate exists and is a file rather than a directory.
    static func isExecutable(_ path: Swift.String) -> Swift.Bool {
        #if os(Windows)
            return path.withCString(encodedAs: UTF16.self) { wide in
                let attributes = unsafe GetFileAttributesW(wide)
                guard attributes != DWORD.max else { return false }
                return attributes & DWORD(FILE_ATTRIBUTE_DIRECTORY) == 0
            }
        #else
            return unsafe path.withCString { unsafe access($0, X_OK) == 0 }
        #endif
    }

    /// The value of the environment variable `name`, or `nil` if it is
    /// unset or empty.
    static func environmentValue(_ name: Swift.String) -> Swift.String? {
        #if os(Windows)
            return name.withCString(encodedAs: UTF16.self) { wide -> Swift.String? in
                // The first call sizes the value (including its NUL);
                // the second fills a buffer of exactly that size, so the
                // returned length is one shorter.
                let capacity = unsafe GetEnvironmentVariableW(wide, nil, 0)
                guard capacity > 0 else { return nil }
                var buffer = [WCHAR](repeating: 0, count: Swift.Int(capacity))
                let written = unsafe GetEnvironmentVariableW(wide, &buffer, capacity)
                guard written > 0, written < capacity else { return nil }
                return Swift.String(decoding: buffer[..<Swift.Int(written)], as: UTF16.self)
            }
        #else
            guard let value = unsafe getenv(name) else { return nil }
            return unsafe Swift.String(cString: value)
        #endif
    }

    /// Locates the helper by ascending from the running test binary's
    /// own directory, rather than by enumerating build layouts.
    ///
    /// Enumerating layouts is what the previous version did, and it
    /// encoded three assumptions that were each false somewhere: that
    /// the configuration is `debug`, that the triple is `apple-macosx`,
    /// and that the layout is SwiftPM's. It passed only on macOS debug
    /// and failed on every release leg and every Linux leg.
    ///
    /// Ascending is layout-independent because the helper is a
    /// **sibling** of the test binary under SwiftPM
    /// (`.build/<triple>/<config>/`) and under xcodebuild
    /// (`.build/out/Products/<Config>-<platform>-<arch>/`), but sits
    /// three levels above it inside a macOS test bundle
    /// (`<Pkg>PackageTests.xctest/Contents/MacOS/`). Walking up covers
    /// all three, and any future layout, without naming one.
    ///
    /// - Returns: an absolute path, or `nil`. Never a bare name:
    ///   `posix_spawn` does not search `PATH` (that is `posix_spawnp`),
    ///   and the configuration below passes no environment, so a bare
    ///   name would surface as an anonymous `ENOENT` naming nothing.
    static func helperPath() -> Swift.String? {
        if let candidate = environmentValue(helperOverride), isExecutable(candidate) {
            return candidate
        }
        for candidate in searchedCandidates() where isExecutable(candidate) {
            return candidate
        }
        return nil
    }

    /// Every path the ascent looks at, in the order it looks at them.
    ///
    /// Shared with the diagnostic below so a failure reports the paths
    /// that were actually tried rather than a reconstruction of them.
    static func searchedCandidates() -> [Swift.String] {
        guard let executable = runningImagePath(),
            let separator = executable.lastIndex(of: pathSeparator)
        else { return [] }
        var directory = Swift.String(executable[..<separator])
        var candidates: [Swift.String] = []
        // 3 covers the deepest known layout (the macOS bundle); 5 is headroom.
        for _ in 0..<5 {
            for name in helperFileNames {
                candidates.append("\(directory)\(pathSeparator)\(name)")
            }
            guard let sep = directory.lastIndex(of: pathSeparator), sep != directory.startIndex
            else { break }
            directory = Swift.String(directory[..<sep])
        }
        return candidates
    }

    /// Runs the helper with `arguments`, stdout and stderr on pipes.
    ///
    /// - Returns: the captured output, or `nil` if the helper could not
    ///   be located or failed to spawn.
    static func run(_ arguments: [Swift.String]) -> Process.Output? {
        guard let path = helperPath() else { return nil }
        let configuration = Process.Spawn.Configuration(
            executable: path,
            arguments: arguments,
            stdout: .pipe,
            stderr: .pipe
        )
        do throws(Process.Error) {
            return try Process.Spawn.run(configuration)
        } catch {
            return nil
        }
    }

    /// A diagnostic naming what was looked for and how to override it.
    ///
    /// "Helper not found" otherwise surfaces as a bare `nil` that names
    /// neither the executable nor the escape hatch, which is a long hunt
    /// from a short message.
    static var notFoundMessage: Swift.String {
        let tried = searchedCandidates()
            .map { "  \($0)" }
            .joined(separator: "\n")
        return """
            helper executable '\(helperName)' not found by ascending from \
            \(runningImagePath() ?? "<running image path unavailable>"). \
            Build the package first, or set \(helperOverride) to its absolute path.
            Paths tried, in order:
            \(tried.isEmpty ? "  <none: running image path unavailable>" : tried)
            """
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
        let output = try #require(HelperProcess.run(["hello"]), "\(HelperProcess.notFoundMessage)")
        #expect(output.status == .exited(code: 0))
        #expect(HelperProcess.stdoutText(output).contains("HELPER-BEGIN hello HELPER-END"))
    }

    @Test
    func `Help output is not discarded when stdout is a pipe`() throws {
        let output = try #require(HelperProcess.run(["--help"]), "\(HelperProcess.notFoundMessage)")
        #expect(output.status == .exited(code: 0))
        let text = HelperProcess.stdoutText(output)
        #expect(!text.isEmpty)
        #expect(text.contains("USAGE:"))
        #expect(text.contains("command-runner-helper"))
    }

    @Test
    func `Unknown-option diagnostic is not discarded when stdout is a pipe`() throws {
        let output = try #require(
            HelperProcess.run(["--bogusflag"]),
            "\(HelperProcess.notFoundMessage)"
        )
        #expect(output.status == .exited(code: 64))
        #expect(HelperProcess.stdoutText(output).contains("--bogusflag"))
    }

    @Test
    func `Missing-argument diagnostic is not discarded when stdout is a pipe`() throws {
        let output = try #require(HelperProcess.run([]), "\(HelperProcess.notFoundMessage)")
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
                "argv \(arguments): \(HelperProcess.notFoundMessage)"
            )
            #expect(
                !(output.stdout ?? []).isEmpty,
                "argv \(arguments) wrote zero bytes to a piped stdout"
            )
        }
    }
}
