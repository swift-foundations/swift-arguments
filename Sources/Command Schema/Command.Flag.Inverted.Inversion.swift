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

extension Command.Flag.Inverted {
    /// The strategy that maps a base long-option name to its
    /// "true" and "false" forms.
    ///
    /// Both supported strategies mirror swift-argument-parser's
    /// `FlagInversion` cases — `prefixedNo` and
    /// `prefixedEnableDisable` — and produce the long-option-name
    /// pairs registered by ``Command/Flag/Inverted``.
    public enum Inversion: Sendable, Hashable, Equatable {
        /// `base` → `--<base>` (true) and `--no-<base>` (false).
        ///
        /// The most common inverted-flag shape; mirrors
        /// swift-argument-parser's `FlagInversion.prefixedNo`.
        case prefixedNo
        /// `base` → `--enable-<base>` (true) and `--disable-<base>` (false).
        ///
        /// Mirrors swift-argument-parser's
        /// `FlagInversion.prefixedEnableDisable` — preferred when the
        /// "off" form needs to read as an explicit verb (`--disable-foo`).
        case prefixedEnableDisable
    }
}
