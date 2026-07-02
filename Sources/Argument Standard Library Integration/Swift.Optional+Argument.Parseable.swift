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

extension Swift.Optional: Argument.Parseable where Wrapped: Argument.Parseable {
    /// Parses `argument` into `.some(value)` when the wrapped type accepts
    /// the string, or returns `nil` when the wrapped parse fails.
    ///
    /// ## Semantics
    ///
    /// Two failure paths exist for an optional-typed schema property:
    ///
    /// 1. **Option absent from argv**: the schema's
    ///    default-value-on-property mechanism leaves the property at its
    ///    declared default (commonly `nil` for `T?`-typed fields). This
    ///    path does NOT route through this initializer — the schema
    ///    parser only invokes `init?(argument:)` when an argv value is
    ///    present to decode.
    ///
    /// 2. **Option present with invalid argv value**: this initializer
    ///    receives the offending string and returns `nil` — the outer
    ///    schema parser sees the `nil` outcome and emits
    ///    `Command.Error.invalidValue` with the original argv text. This
    ///    matches the per-argument-decode semantics of every other
    ///    `Argument.Parseable` conformer.
    ///
    /// Mapping invalid → nil at this layer would lose the diagnostic
    /// (the schema parser cannot distinguish "user typed something
    /// invalid" from "user explicitly chose absent") and is rejected by
    /// the [FAM-009] sibling-protocol failure model.
    ///
    /// Produces `.some(value)` when `Wrapped` accepts the string; fails
    /// (returns `nil`) when `Wrapped` rejects it (the schema converts
    /// `nil` into a typed `Command.Error.invalidValue`).
    ///
    /// - Parameter argument: The argv element to parse.
    @inlinable
    public init?(argument: String) {
        guard let wrapped = Wrapped(argument: argument) else {
            return nil
        }
        self = .some(wrapped)
    }
}
