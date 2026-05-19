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
    /// Per-case row content for an enumerable-flag help entry.
    ///
    /// ``Command/HelpEnumerableCase`` is the non-generic carrier the
    /// help-text visitor uses to materialise per-case long-option names
    /// and per-case ``Argument/Help`` documentation for
    /// ``Command/Flag/Enumerable`` declarations. The enumerable enum's
    /// associated type is erased at row-collection time so visitors
    /// don't carry the generic forward to render time.
    ///
    /// Compound naming (`HelpEnumerableCase` rather than nested
    /// `Command.Help.EnumerableCase`) mirrors the
    /// ``Command/HelpRow`` shape — the generic ``Command/Help``
    /// struct (`Command.Help<Root>`) occupies the
    /// nested namespace. The compound is `@usableFromInline internal`
    /// — strictly an implementation detail of the help target.
    @usableFromInline
    internal struct HelpEnumerableCase: Sendable {
        /// The long-option string for this case (`add`, `multiply`, …).
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
