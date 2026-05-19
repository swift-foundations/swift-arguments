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
    /// Invocation context passed to a running ``Command/Protocol``.
    ///
    /// `Command.Context` carries information about the command's
    /// invocation that the running command may need but should not have
    /// to look up via globals (program name, raw argv after parsing).
    /// v1 keeps the surface intentionally minimal — extensions can land
    /// when consumers surface need.
    ///
    /// ## v1 scope
    ///
    /// - ``executableName`` — the program name (`argv[0]`) as observed
    ///   at invocation.
    /// - ``remainingArguments`` — the post-`--` operands collected by
    ///   parsing, in argv order.
    public struct Context: Sendable, Hashable, Equatable {
        /// The program-name slot (`argv[0]`) at invocation time.
        public let executableName: String

        /// The operands collected after a `--` end-of-options separator,
        /// in argv order. Empty when no `--` was present.
        public let remainingArguments: [String]

        /// Creates a context.
        ///
        /// - Parameters:
        ///   - executableName: The program name; defaults to empty.
        ///   - remainingArguments: Post-`--` operands; defaults to empty.
        @inlinable
        public init(
            executableName: String = "",
            remainingArguments: [String] = []
        ) {
            self.executableName = executableName
            self.remainingArguments = remainingArguments
        }
    }
}
