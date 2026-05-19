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
    /// Internal non-generic carrier for help-text rows.
    ///
    /// `Command.HelpRow` is the row representation accumulated during
    /// help-text emission by ``Command/Help/Visitor`` and shared with
    /// ``Command/Help/OptionGroupRowCollector`` so option-group
    /// sub-schemas (rooted on a fragment type `G`) can splice their
    /// rows directly without per-Root re-wrapping.
    ///
    /// Compound naming (`HelpRow` rather than nested
    /// `Command.Help.Row`) is used because the generic
    /// ``Command/Help`` struct (`Command.Help<Root>`) occupies that
    /// nested namespace. The compound is `@usableFromInline internal`
    /// — strictly an implementation detail of the help target, not a
    /// public API surface, so the convention against compound names
    /// (which applies to PUBLIC types per [API-NAME-002]) does not
    /// bind here.
    @usableFromInline
    internal enum HelpRow: Sendable {
        case positional(name: String, placeholder: String, help: Argument.Help, visibility: Argument.Visibility)
        /// An array-positional ("Many") row — distinguished from a
        /// single ``positional`` so the USAGE / ARGUMENTS layouts can
        /// emit a trailing `...` ellipsis.
        case positionalMany(name: String, placeholder: String, help: Argument.Help, visibility: Argument.Visibility)
        case option(name: Argument.Name, placeholder: String, help: Argument.Help, visibility: Argument.Visibility)
        /// A repeatable-option ("Many") row — distinguished from a
        /// single ``option`` so the USAGE layout can emit `[--name <v>]...`
        /// with the trailing `...` marker.
        case optionMany(name: Argument.Name, placeholder: String, help: Argument.Help, visibility: Argument.Visibility)
        case flag(name: Argument.Name, help: Argument.Help, visibility: Argument.Visibility)
        /// A count-flag row — rendered as `-vvv` / `--verbose` style hint
        /// so help text signals the repeatable counter semantics.
        case flagCount(name: Argument.Name, help: Argument.Help, visibility: Argument.Visibility)
        /// An inverted-flag row — carries both derived long forms
        /// (true/false) so help text shows both names as one entry.
        case flagInverted(trueName: String, falseName: String, help: Argument.Help, visibility: Argument.Visibility)
        /// An enumerable-flag row — carries the per-case long-name +
        /// help pairs so help text emits one row per case under a
        /// shared group header.
        case flagEnumerable(cases: [Command.HelpEnumerableCase], help: Argument.Help, visibility: Argument.Visibility)
        case subcommand(name: String, help: Argument.Help, visibility: Argument.Visibility)
    }
}
