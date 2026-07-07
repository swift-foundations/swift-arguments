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

extension Swift.Optional: Argument.Serializable where Wrapped: Argument.Serializable {
    /// Renders an optional value to its argv-element string form.
    ///
    /// - `.some(value)` delegates to the wrapped value's
    ///   ``Argument/Serializable/argumentDescription``.
    /// - `.none` renders as the empty string. Help-text emission usually
    ///   skips the `(default: ...)` annotation when the rendered string
    ///   is empty — schemas declaring `T?`-typed properties with `nil`
    ///   defaults therefore avoid noise like `(default: )` in `--help`.
    ///
    /// Schemas wanting to label nil defaults explicitly (such as
    /// `(default: <none>)`) should set
    /// ``Argument/Help/defaults`` directly on the
    /// ``Argument/Option`` declaration rather than relying on this
    /// rendering.
    @inlinable
    public var argumentDescription: String {
        switch self {
        case .some(let value):
            return value.argumentDescription

        case .none:
            return ""
        }
    }
}
