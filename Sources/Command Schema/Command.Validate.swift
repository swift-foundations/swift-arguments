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

extension Command.`Protocol` {
    /// Default implementation of the ``Command/Protocol/validate()``
    /// requirement — a no-op.
    ///
    /// The protocol requirement is necessary so that
    /// ``Command/parse(_:from:initial:)`` can dispatch
    /// `root.validate()` through the witness table and reach the
    /// conformer's override. Without the requirement the generic-`C`
    /// context would resolve to this extension method statically and
    /// the conformer's `validate()` would never run.
    ///
    /// ## Overriding
    ///
    /// Conformers SHADOW the default by declaring their own
    /// `validate()` on the concrete type:
    ///
    /// ```swift
    /// struct Build: Command.`Protocol` {
    ///     var fromFile: String?
    ///     var fromStdin: Bool = false
    ///     // ...
    ///
    ///     mutating func validate() throws(Command.Error) {
    ///         let sources = [fromFile != nil, fromStdin].filter { $0 }.count
    ///         guard sources == 1 else {
    ///             throw .validationFailed(
    ///                 reason: "Exactly one input source must be specified."
    ///             )
    ///         }
    ///     }
    ///
    ///     mutating func run() async throws(Command.Error) { /* ... */ }
    /// }
    /// ```
    @inlinable
    public mutating func validate() throws(Command.Error) {
        // Intentional no-op default.
    }
}
