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
    /// The Schema-internal help namespace for sub-command rendering.
    ///
    /// `Command.Subcommand.Help` hosts the help-rendering visitor used
    /// by ``Command/Subcommand/appendHelp(to:fullCommandName:)`` to
    /// produce per-subcommand `--help` output. It lives at the Schema
    /// target so ``Command/Subcommand/Binding`` conformance can render
    /// without depending on the `Command Help` target.
    ///
    /// Per the design doc §2.3 v1.0.8, sub-help rendering output mirrors
    /// the top-level ``Command/Help`` output shape. A v2 cleanup may
    /// consolidate the two render paths.
    public enum Help {}
}
