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

extension Argument.Environment {
    /// Test-support overlay helper.
    ///
    /// A `Swift.String`-typed bridge over swift-environment's
    /// ``Environment/withOverlay(_:perform:)``. The bridge isolates the
    /// `internal import Environment` (which transitively re-exports the
    /// `String_Primitives` `~Copyable` `String` symbol) so test bodies
    /// that call this method work with `Swift.String` exclusively.
    ///
    /// Tests use this to scope env-var values for a single parse
    /// without mutating process state and without per-test
    /// `setenv`/`unsetenv` race conditions under parallel execution.
    ///
    /// The accessor lives at L3 test-support because it composes
    /// swift-environment's TaskLocal-overlay machinery — it is not part
    /// of the L1 ``Argument/Environment`` vocabulary surface.
    public static func withOverlay<R, E: Swift.Error>(
        _ values: [Swift.String: Swift.String],
        perform body: () throws(E) -> R
    ) throws(E) -> R {
        try Environment.withOverlay(values, perform: body)
    }
}
