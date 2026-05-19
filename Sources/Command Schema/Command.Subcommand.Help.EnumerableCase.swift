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

extension Command.Subcommand.Help {
    /// Per-case row content for an enumerable-flag help entry in
    /// subcommand help rendering.
    ///
    /// Mirrors ``Command/HelpEnumerableCase`` exactly — duplicated
    /// because `Command Schema` cannot depend on `Command Help` and
    /// the two row enums live in different targets.
    @usableFromInline
    internal struct EnumerableCase: Sendable {
        /// The long-option string for this case.
        @usableFromInline let name: String
        /// The per-case documentation.
        @usableFromInline let help: Argument.Help

        @usableFromInline
        internal init(name: String, help: Argument.Help) {
            self.name = name
            self.help = help
        }
    }
}
