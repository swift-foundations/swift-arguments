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

extension Command.Subcommand {
    /// The existential carrier for sum-type subcommand bindings.
    ///
    /// `Command.Subcommand.Binding<Root>` is the heterogeneity-bridging
    /// protocol that lets ``Command/Subcommand/Group`` hold a list of
    /// subcommand bindings whose `Sub` types differ:
    ///
    /// ```swift
    /// Command.Subcommand.Group {
    ///     Command.Subcommand.Case("clone", initial: Clone.init, map: Git.clone)
    ///     Command.Subcommand.Case("status", initial: Status.init, map: Git.status)
    /// }
    /// ```
    ///
    /// `Clone` and `Status` are different types; the Group stores them as
    /// `[any Command.Subcommand.Binding<Root>]`. The protocol's
    /// `parse(subArgv:)` and `appendHelp(to:fullCommandName:)` requirements
    /// recover the static `Sub` type per binding at the call site.
    ///
    /// ## Conformers
    ///
    /// - ``Command/Subcommand/Case`` — the only stdlib conformer.
    ///
    /// Per [API-IMPL-005], one conformer per file.
    public protocol Binding<Root>: Sendable {
        /// The Root command type whose enum case this binding wraps to.
        associatedtype Root: Sendable

        /// The CLI subcommand name (e.g., `"clone"`).
        var name: String { get }

        /// Alternative names this subcommand also responds to.
        var aliases: [String] { get }

        /// Whether this subcommand appears in help text.
        var visibility: Argument.Visibility { get }

        /// Documentation for this subcommand.
        var help: Argument.Help { get }

        /// Whether this case is the default subcommand.
        ///
        /// When `true`, the parse visitor dispatches this binding when
        /// argv supplies no subcommand name. At most one binding per
        /// ``Command/Subcommand/Group`` may carry `isDefault = true`.
        var isDefault: Bool { get }

        /// Parses the sub-argv slice (i.e., the argv elements appearing
        /// after the subcommand name) into the matching `Root` enum case.
        ///
        /// Implementations call ``Command/parse(_:from:initial:)`` against
        /// the sub-command's schema and then wrap the result via the
        /// binding's `map` closure.
        ///
        /// - Parameter subArgv: The argv elements following the
        ///   subcommand name (subcommand name itself already consumed).
        /// - Returns: The wrapped Root enum value.
        /// - Throws: ``Command/Error`` on tokenize/parse failure.
        func parse(subArgv: [String]) throws(Command.Error) -> Root

        /// Appends formatted help text for this subcommand's sub-schema
        /// into `buffer`. Used for per-subcommand `--help` rendering
        /// (e.g., `git clone --help`).
        ///
        /// The implementation duplicates the help-rendering logic of
        /// ``Command/Help/Visitor`` rather than depending on the
        /// `Command Help` target — `Command Schema` must remain
        /// dependency-free of the help-text formatter to preserve the
        /// existing target layering. The duplication is a v1 trade-off;
        /// a v2 cleanup may consolidate via a Schema-level rendering
        /// primitive.
        ///
        /// - Parameters:
        ///   - buffer: The buffer accumulating help text.
        ///   - fullCommandName: The full invocation path
        ///     (e.g., `"git clone"`) used in the rendered USAGE line.
        func appendHelp(to buffer: inout String, fullCommandName: String)
    }
}
