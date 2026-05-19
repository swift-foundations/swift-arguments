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
    /// One-way parse from a single argv-element string into a value.
    ///
    /// `Argument.Parseable` is the parse-only half of ``Argument/Codable``.
    /// A conformer can construct itself from a single argv-element `String`
    /// or return `nil` if the string is not a valid representation of the
    /// conformer's type.
    ///
    /// ## Failure model
    ///
    /// Returning `nil` from ``init(argument:)-shvr`` is the standard
    /// failure signal — schema-driven parsing converts a `nil` outcome
    /// into a typed `Command.Error.invalidValue` carrying the offending
    /// argv string. This mirrors `Swift.Int.init?(_:)` /
    /// `Swift.Double.init?(_:)`-style parsing.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Stdlib conformances ship with swift-arguments:
    /// let n: Int? = Int(argument: "42")              // Optional(42)
    /// let b: Bool? = Bool(argument: "true")          // Optional(true)
    /// let s: String? = String(argument: "hello")     // Optional("hello")
    ///
    /// // Custom conformance for parse-only types:
    /// extension MyToken: Argument.Parseable {
    ///     public init?(argument: String) { ... }
    /// }
    /// ```
    public protocol Parseable: Sendable {
        /// Parses `argument` into a value, or returns `nil` if the string
        /// is not a valid representation.
        init?(argument: String)
    }
}
