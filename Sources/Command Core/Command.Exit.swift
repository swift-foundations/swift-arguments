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

extension Command {
    /// A typed exit-code wrapper.
    ///
    /// `Command.Exit` carries a 32-bit signed exit code matching POSIX's
    /// `_Exit(int)` and Win32's `ExitProcess(UINT)` conventions. Convenience
    /// constants ``success`` and ``failure`` cover the canonical paths;
    /// custom codes thread through ``init(code:)``.
    public struct Exit: Sendable, Hashable, Equatable {
        /// The numeric exit code returned to the operating system.
        public let code: Int32

        /// Creates an exit value with the given numeric code.
        @inlinable
        public init(code: Int32) {
            self.code = code
        }
    }
}

extension Command.Exit {
    /// Exit code 0 — success.
    public static let success: Command.Exit = .init(code: 0)

    /// Exit code 1 — generic failure.
    public static let failure: Command.Exit = .init(code: 1)
}
