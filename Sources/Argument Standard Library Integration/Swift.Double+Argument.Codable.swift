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

extension Swift.Double: Argument.Codable {
    /// Parses `argument` as a double-precision floating-point number.
    @inlinable
    public init?(argument: String) {
        self.init(argument)
    }

    /// The standard `Double` string form.
    @inlinable
    public var argumentDescription: String {
        String(self)
    }
}
