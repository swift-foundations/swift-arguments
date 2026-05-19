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

public import Argument_Primitives

extension Argument {
    /// The L3 argv tokenizer namespace.
    ///
    /// `Argument.Tokenizer` is the swift-arguments-side composition that
    /// turns a raw `[String]` argv into a normalized `[Argument.Token]`
    /// stream consumable by the L3 schema-driven parser.
    ///
    /// Per §3.4 v1.0.7 of the design, GNU long-options (`--long`,
    /// `--long=value`, `--long value`) are handled INLINE at L3 — there
    /// is no separate `swift-gnu` L2 package in v1. POSIX 12.2 short-flag
    /// forms are delegated to ``IEEE_1003/UtilitySyntax/Tokenizer``.
    public enum Tokenizer {}
}
