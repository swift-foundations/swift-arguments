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

extension Swift.UInt: Argument.Codable {
    /// Parses `argument` as a non-negative decimal integer.
    @inlinable
    public init?(argument: String) {
        self.init(argument)
    }

    /// The base-10 string form.
    @inlinable
    public var argumentDescription: String {
        String(self)
    }
}
