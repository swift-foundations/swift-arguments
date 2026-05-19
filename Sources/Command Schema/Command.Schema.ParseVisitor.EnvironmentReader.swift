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

internal import Environment

extension Command.Schema.ParseVisitor {
    /// Reads an environment-variable value via swift-environment's
    /// ``Environment/Task/read(_:)``.
    ///
    /// Consults the ``Environment/withOverlay(_:perform:)`` TaskLocal
    /// overlay first (when present) and falls back to the process
    /// environment. The overlay layer means consumers and tests can
    /// scope env-var values to a single call without touching the
    /// process state — preserving testability and child-process
    /// isolation semantics documented at ``Environment/Task``.
    ///
    /// The bridge is isolated in its own file so the `internal import
    /// Environment` (which transitively re-exports the `String_Primitives`
    /// `~Copyable` `String` symbol) does not shadow `Swift.String` in the
    /// rest of the parse-visitor implementation. The bridge accepts and
    /// returns `Swift.String` exclusively.
    ///
    /// - Parameter name: The variable name.
    /// - Returns: The variable's value, or `nil` if unset.
    @usableFromInline
    internal static func readEnvironmentVariable(_ name: Swift.String) -> Swift.String? {
        Environment.task.read(name)
    }
}
