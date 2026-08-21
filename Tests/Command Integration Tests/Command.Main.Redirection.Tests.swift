import Process
import Testing

@testable import Command_Test_Support

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(WinSDK)
    import WinSDK
#endif

private enum HelperProcess {}

extension HelperProcess {

    static let helperName = "command-runner-helper"

    #if os(Windows)
        static let helperFileNames = ["\(helperName).exe", helperName]
    #else
        static let helperFileNames = [helperName]
    #endif

    #if os(Windows)
        static let pathSeparator: Swift.Character = "\\"
    #else
        static let pathSeparator: Swift.Character = "/"
    #endif

    static let helperOverride = "COMMAND_RUNNER_HELPER"

    static func string(fromNulTerminated buffer: [CChar]) -> Swift.String {
        unsafe buffer.withUnsafeBufferPointer { pointer in
            guard let baseAddress = pointer.baseAddress else { return "" }
            return unsafe Swift.String(cString: baseAddress)
        }
    }

    #if canImport(Darwin)

        static let imageMarker: @convention(c) () -> Void = {}
    #endif

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

            var buffer = [WCHAR](repeating: 0, count: 32768)
            let written = unsafe GetModuleFileNameW(nil, &buffer, DWORD(buffer.count))
            guard written > 0, written < DWORD(buffer.count) else { return nil }
            return Swift.String(decoding: buffer[..<Swift.Int(written)], as: UTF16.self)
        #else
            return nil
        #endif
    }

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

    static func environmentValue(_ name: Swift.String) -> Swift.String? {
        #if os(Windows)
            return name.withCString(encodedAs: UTF16.self) { wide -> Swift.String? in

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

    static func helperPath() -> Swift.String? {
        if let candidate = environmentValue(helperOverride), isExecutable(candidate) {
            return candidate
        }
        for candidate in searchedCandidates() where isExecutable(candidate) {
            return candidate
        }
        return nil
    }

    static func searchedCandidates() -> [Swift.String] {
        guard let executable = runningImagePath(),
            let separator = executable.lastIndex(of: pathSeparator)
        else { return [] }
        var directory = Swift.String(executable[..<separator])
        var candidates: [Swift.String] = []

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

    static func stdoutText(_ output: Process.Output) -> Swift.String {
        Swift.String(decoding: output.stdout ?? [], as: UTF8.self)
    }
}

@Suite
struct `Command.main redirected-output Tests` {

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
