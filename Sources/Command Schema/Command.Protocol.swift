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
    /// Conformance for one CLI command.
    ///
    /// `Command.\`Protocol\`` is the single, always-async command-conformance
    /// protocol per U3 v1.0.4 (see
    /// `swift-institute/Research/2026-05-15-command-protocol-sync-async-design.md`).
    /// There is no `Command.Async.Protocol` — sync command bodies omit
    /// `await` and the async-runtime overhead is acceptable
    /// institute-wide. The decision matches the unanimous single-shape
    /// precedent of `Parser.\`Protocol\``, `Serializer.\`Protocol\``,
    /// and `Coder.\`Protocol\`` at L1.
    ///
    /// ## Conformance recipe
    ///
    /// ```swift
    /// struct Repeat: Command.`Protocol` {
    ///     var phrase: String
    ///     var count: Int = 2
    ///     var counter: Bool = false
    ///
    ///     static var configuration: Command.Configuration {
    ///         Command.Configuration(name: "repeat", abstract: "Repeats your input phrase.")
    ///     }
    ///
    ///     static var schema: Command.Schema.Definition<Self> {
    ///         Command.Schema.Definition {
    ///             Command.Positional(\.phrase, help: .init(abstract: "The phrase to repeat."))
    ///             Command.Option(\.count, name: .long("count"),
    ///                             help: .init(abstract: "Number of repetitions."))
    ///             Command.Flag(\.counter, name: .long("counter"),
    ///                          help: .init(abstract: "Include a counter."))
    ///         }
    ///     }
    ///
    ///     mutating func run() async throws(Command.Error) {
    ///         for i in 1...count {
    ///             print(counter ? "\(i): \(phrase)" : phrase)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## Mutating, not consuming
    ///
    /// `run()` is `mutating` (Copyable default per P0 REFUTED — see the
    /// design doc §VI P0 v1.0.3). `consuming func run()` for
    /// kernel-resource-holding commands is a v2 feature behind
    /// `Command.Resource.\`Protocol\`` (D8 deferred).
    public protocol `Protocol`: Sendable {
        /// The typed-throws domain for this command. Defaults to
        /// ``Command/Error`` but conformers MAY narrow.
        associatedtype Failure: Swift.Error = Command.Error

        /// Static metadata for this command.
        static var configuration: Command.Configuration { get }

        /// The argument schema bound against fields on `Self`.
        ///
        /// Per §2.2 of the design, the schema is data — the same value
        /// drives parsing argv into `Self` and emitting help text via
        /// ``Command/Help``.
        static var schema: Command.Schema.Definition<Self> { get }

        /// A user-overridable post-decode validation hook.
        ///
        /// Runs after schema-driven decoding but before ``run()``. Use it
        /// to enforce cross-field invariants that the schema cannot encode
        /// structurally — for example "exactly one of `--from-file` /
        /// `--from-stdin`" or "the value of `--count` must be positive
        /// when `--mode=repeat`".
        ///
        /// A default no-op is provided in ``Command/Protocol/validate()``
        /// (extension); conformers SHADOW the default by declaring their
        /// own `validate()` method. The protocol requirement is necessary
        /// for the witness-table dispatch — the parser calls
        /// `root.validate()` through the generic-`C` constraint, and
        /// without the requirement the conformer's override would not be
        /// reached.
        ///
        /// Errors raised here surface as ``Command/Error`` from
        /// ``Command/parse(_:from:initial:)``. Prefer
        /// ``Command/Error/validationFailed(reason:)`` for diagnostics.
        mutating func validate() throws(Command.Error)

        /// The command's behavior.
        ///
        /// Sync command bodies simply omit `await` and the async-runtime
        /// overhead does not materialize.
        mutating func run() async throws(Failure)
    }
}
