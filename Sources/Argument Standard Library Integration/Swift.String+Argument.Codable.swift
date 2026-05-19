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

extension Swift.String: Argument.Codable {
    /// Adopts `argument` as-is.
    ///
    /// Never returns `nil` — every argv string is a valid `String`. The
    /// failable initializer is required by the protocol but always
    /// succeeds for `String`.
    @inlinable
    public init?(argument: String) {
        self = argument
    }

    /// The string itself, unmodified.
    @inlinable
    public var argumentDescription: String {
        self
    }
}
