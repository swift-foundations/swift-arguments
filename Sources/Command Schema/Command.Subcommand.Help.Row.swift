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
    /// A non-generic row accumulated during sub-command help-text emission.
    ///
    /// `Command.Subcommand.Help.Row` mirrors the shape of
    /// ``Command/HelpRow`` but lives in the `Command Schema` target,
    /// keeping the Schema target free of any dependency on the
    /// `Command Help` target per the v1 layering contract.
    ///
    /// Hoisting Row out of the per-Root generic
    /// ``Command/Subcommand/Help/Visitor`` lets option-group sub-schemas
    /// (rooted on a fragment type `G`) splice their rows directly into
    /// the parent visitor's row list without per-Root re-wrapping.
    @usableFromInline
    internal enum Row: Sendable {
        case positional(name: String, valueName: String, help: Argument.Help, visibility: Argument.Visibility)
        /// An array-positional ("Many") row.
        case positionalMany(name: String, valueName: String, help: Argument.Help, visibility: Argument.Visibility)
        case option(name: Argument.Name, valueName: String, help: Argument.Help, visibility: Argument.Visibility)
        /// A repeatable-option ("Many") row.
        case optionMany(name: Argument.Name, valueName: String, help: Argument.Help, visibility: Argument.Visibility)
        case flag(name: Argument.Name, help: Argument.Help, visibility: Argument.Visibility)
        /// A count-flag row.
        case flagCount(name: Argument.Name, help: Argument.Help, visibility: Argument.Visibility)
        /// An inverted-flag row.
        case flagInverted(trueName: String, falseName: String, help: Argument.Help, visibility: Argument.Visibility)
        /// An enumerable-flag row.
        case flagEnumerable(cases: [Command.Subcommand.Help.EnumerableCase], help: Argument.Help, visibility: Argument.Visibility)
        case subcommand(name: String, help: Argument.Help, visibility: Argument.Visibility)
    }
}
