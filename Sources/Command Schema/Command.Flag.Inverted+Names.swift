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

extension Command.Flag.Inverted {
    /// The long-option string that selects the `true` value (e.g.,
    /// `"feature"` or `"enable-feature"`).
    ///
    /// Derived from ``base`` and ``inversion`` at access time; both
    /// forms are guaranteed to be valid long-name strings by
    /// construction because ``base`` is already a validated
    /// ``Argument/Name/Long``.
    @inlinable
    public var trueName: String {
        switch inversion {
        case .prefixedNo:
            return base.string

        case .prefixedEnableDisable:
            return "enable-" + base.string
        }
    }

    /// The long-option string that selects the `false` value (e.g.,
    /// `"no-feature"` or `"disable-feature"`).
    @inlinable
    public var falseName: String {
        switch inversion {
        case .prefixedNo:
            return "no-" + base.string

        case .prefixedEnableDisable:
            return "disable-" + base.string
        }
    }
}
