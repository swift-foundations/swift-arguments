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

extension Command {
    /// Default-value-derivation helpers shared by
    /// ``Command/Help/Visitor`` and
    /// ``Command/HelpOptionGroupRowCollector``.
    ///
    /// Routes the per-binding-type rendering rules documented in the
    /// swift-arguments design doc v1.0.16 §3.13 through a single
    /// implementation so the parent visitor and the fragment collector
    /// emit identical default-line content.
    ///
    /// Compound naming (`HelpDefault` rather than nested
    /// `Command.Help.Default`) is used because the generic
    /// ``Command/Help`` struct (`Command.Help<Root>`) occupies that
    /// nested namespace. The compound is `@usableFromInline internal` —
    /// strictly an implementation detail of the help target.
    @usableFromInline
    internal enum HelpDefault {}
}

extension Command.HelpDefault {
    /// Derives a default-value description from `initial` against
    /// the supplied `keyPath`, swapping it into
    /// `help.defaults` only when (a) the user did not
    /// declare one explicitly AND (b) initial is non-`nil`.
    ///
    /// - Parameters:
    ///   - help: The original L1 ``Argument/Help`` carrying the
    ///     user-declared documentation. Returned unchanged when
    ///     `help.defaults` is non-`nil` — user precedence
    ///     is preserved.
    ///   - initial: The seed `Root` instance from which to derive a
    ///     default. When `nil`, auto-derivation is skipped and
    ///     `help` is returned unchanged.
    ///   - keyPath: The `Root → V` key path identifying the field
    ///     whose initial value supplies the rendered default.
    /// - Returns: `help` with `defaults` populated when
    ///   both the user-explicit slot is empty and a default can be
    ///   derived; `help` unchanged otherwise.
    @usableFromInline
    internal static func inject<Root, V>(
        _ help: Argument.Help,
        initial: Root?,
        keyPath: WritableKeyPath<Root, V> & Sendable
    ) -> Argument.Help {
        if help.defaults != nil { return help }
        guard let initial else { return help }
        let value = initial[keyPath: keyPath]
        let rendered = Self.render(value)
        guard let rendered else { return help }
        return Argument.Help(
            abstract: help.abstract,
            discussion: help.discussion,
            placeholder: help.placeholder,
            defaults: rendered
        )
    }

    /// Renders a typed default value to its display string per the
    /// per-binding-type rules in §3.13.
    ///
    /// Returns `nil` when the value should NOT render a default in
    /// help text — such as a `nil` Optional binding, an empty array
    /// binding for `Many`, a `Bool` binding for a plain `Flag`, or
    /// an `Int` `0` for a `Flag.Count` initial.
    @usableFromInline
    internal static func render<V>(_ value: V) -> String? {
        // Optional-aware path: a `.none` initial value SHOULD NOT
        // render a default line; a `.some(v)` renders
        // `String(describing: v)`.
        if let optional = value as? (any _OptionalConvertible) {
            return optional._unwrapped.map { Swift.String(describing: $0) }
        }

        // Array-aware path: an empty array renders nothing; a
        // non-empty array renders `[a, b, c]` via
        // `String(describing:)`.
        // `V` is an unconstrained generic parameter here — an existential
        // cast is the only way to probe for Collection conformance at
        // runtime for an arbitrary binding type.
        // swiftlint:disable:next no_any_protocol_existential
        if let collection = value as? (any Collection), collection.isEmpty {
            return nil
        }

        // Bool-aware suppression: plain `Bool` initial values do
        // NOT render a default line. `Bool`-flag defaults are
        // present/absent semantics; rendering `(default: false)` on
        // every flag would be noisy. `Flag.Inverted` is handled in
        // its visit-time entry point with explicit boolean → name
        // selection because the row carries both names — the visitor
        // walks that branch separately and bypasses this helper.
        if value is Bool { return nil }

        // Int-aware suppression: `Flag.Count` with `0` initial
        // suppresses its default render; the visitor's
        // visit(flagCount:) path routes through here with `keyPath`'d
        // `Int` and a `0` value surfaces as `nil`.
        if let intValue = value as? Int, intValue == 0 {
            return nil
        }

        return Swift.String(describing: value)
    }
}

/// Internal Optional-unwrap helper.
///
/// Swift's protocol-conformance for `Optional` doesn't expose a
/// type-erased "unwrap" surface at the language level; the value-witness
/// table is the only language-level mechanism. We declare a tiny private
/// protocol with a retroactive `extension Optional` conformance so `as?`
/// recovers the inner value uniformly.
@usableFromInline
internal protocol _OptionalConvertible {
    var _unwrapped: Any? { get }
}

extension Optional: _OptionalConvertible {
    @usableFromInline
    internal var _unwrapped: Any? {
        switch self {
        case .none: return nil
        case .some(let value): return value
        }
    }
}
