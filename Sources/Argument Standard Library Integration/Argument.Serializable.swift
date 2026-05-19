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
    /// One-way serialize from a value to a single argv-element string.
    ///
    /// `Argument.Serializable` is the serialize-only half of
    /// ``Argument/Codable``. A conformer provides
    /// ``argumentDescription`` rendering itself to a single argv-element
    /// `String` — the form a CLI consumer would type to specify the
    /// value at invocation time.
    ///
    /// ## Distinction from `CustomStringConvertible`
    ///
    /// `argumentDescription` is intentionally separate from `description`:
    /// the argv-form may differ from the human-readable form. For example,
    /// a date type might have `description = "2026-05-17 (Sunday)"` but
    /// `argumentDescription = "2026-05-17"`. The argv-form is what
    /// help-text emission and `--default-value` rendering use.
    ///
    /// ## Example
    ///
    /// ```swift
    /// extension Path: Argument.Serializable {
    ///     public var argumentDescription: String { absoluteString }
    /// }
    /// ```
    public protocol Serializable: Sendable {
        /// The argv-form of this value — what a CLI consumer would type
        /// to specify it.
        var argumentDescription: String { get }
    }
}
