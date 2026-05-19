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

extension Swift.Bool: Argument.Codable {
    /// Parses `argument` as a boolean.
    ///
    /// Accepts `"true"` / `"false"` (case-sensitive, matching
    /// `Swift.Bool.init?(_:)`); returns `nil` otherwise. Schema layers
    /// using ``Argument/Flag`` typically do not pass the value through
    /// here — flags toggle on presence — but explicit `--feature true` /
    /// `--feature false` argv forms route here.
    @inlinable
    public init?(argument: String) {
        self.init(argument)
    }

    /// The argv-form: `"true"` or `"false"`.
    @inlinable
    public var argumentDescription: String {
        String(self)
    }
}
