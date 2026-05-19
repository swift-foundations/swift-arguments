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
    /// Two-direction conversion between a value and its argv-string form.
    ///
    /// `Argument.Codable` is the sibling format-Codable protocol for argv
    /// argument values. A conformer can both:
    ///
    /// - Parse itself from a single argv-element `String` (per
    ///   ``init(argument:)``).
    /// - Render itself to a single argv-element `String` (per
    ///   ``argumentDescription``).
    ///
    /// Per [FAM-009] hybrid placement rule, this protocol lives at L3
    /// `swift-arguments` (not L1 `swift-argument-primitives`) because
    /// it bridges `Self` ↔ `Swift.String` — exactly the substrate-friction
    /// pattern that [PRIM-FOUND-004] gates at L1.
    ///
    /// ## Sibling, not a refinement
    ///
    /// `Argument.Codable` does NOT refine the canonical
    /// `Coder_Primitives.Codable`. It is a *sibling* protocol per the
    /// family-codable-convention: one format ≠ canonical-format choice.
    /// `Int: Argument.Codable` can coexist with `Int: JSON.Codable`,
    /// `Int: Binary.Codable`, etc. — each format owns its own conformance.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Built-in stdlib conformances ship with swift-arguments:
    /// let count: Int? = Int(argument: "42")          // Optional(42)
    /// let invalid: Int? = Int(argument: "not-num")   // nil
    ///
    /// // Custom conformance:
    /// extension Path: Argument.Codable {
    ///     public init?(argument: String) {
    ///         guard let url = URL(string: argument) else { return nil }
    ///         self = .init(url: url)
    ///     }
    ///     public var argumentDescription: String { absoluteString }
    /// }
    /// ```
    public protocol Codable: Argument.Parseable, Argument.Serializable {}
}
