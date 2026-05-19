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

extension Swift.Int: Argument.Codable {
    /// Parses `argument` as a decimal integer.
    ///
    /// Delegates to `Int.init?(_:)` for the standard-library numeric
    /// parse. Returns `nil` when the string does not represent a valid
    /// `Int`.
    @inlinable
    public init?(argument: String) {
        self.init(argument)
    }

    /// The base-10 string form, matching `String(self)`.
    @inlinable
    public var argumentDescription: String {
        String(self)
    }
}
