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

extension Command.Subcommand {
    /// Default-value-derivation helpers shared by
    /// ``Command/Subcommand/Help/Visitor`` and
    /// ``Command/Subcommand/Help/OptionGroupRowCollector``.
    ///
    /// Mirrors the structure of ``Command/HelpDefault`` (in the
    /// `Command Help` target) so the sub-help rendering path emits
    /// identical default-line content as the top-level help path. The
    /// duplication is intentional per the v1 layering note documented on
    /// ``Command/Subcommand/Help/Visitor`` — the Schema target must
    /// remain dependency-free of the help-text formatter.
    @usableFromInline
    internal enum HelpDefault {
        /// Derives a default-value description from `initial` against
        /// the supplied `keyPath`, swapping it into
        /// `help.defaultDescription` only when (a) the user did not
        /// declare one explicitly AND (b) initial is non-`nil`.
        @usableFromInline
        internal static func inject<Root, V>(
            _ help: Argument.Help,
            initial: Root?,
            keyPath: WritableKeyPath<Root, V> & Sendable
        ) -> Argument.Help {
            if help.defaultDescription != nil { return help }
            guard let initial else { return help }
            let value = initial[keyPath: keyPath]
            let rendered = Self.render(value)
            guard let rendered else { return help }
            return Argument.Help(
                abstract: help.abstract,
                discussion: help.discussion,
                valueDescription: help.valueDescription,
                defaultDescription: rendered
            )
        }

        /// Renders a typed default value to its display string per the
        /// per-binding-type rules in §3.13.
        @usableFromInline
        internal static func render<V>(_ value: V) -> String? {
            if let optional = value as? (any _SubcommandOptionalConvertible) {
                return optional._unwrapped.map { Swift.String(describing: $0) }
            }
            if let collection = value as? (any Collection), collection.isEmpty {
                return nil
            }
            if value is Bool { return nil }
            if let intValue = value as? Int, intValue == 0 {
                return nil
            }
            return Swift.String(describing: value)
        }
    }
}

/// Internal Optional-unwrap helper for the Schema target.
///
/// Mirrors the top-level helper in
/// `Command Help/Command.Help.Default.swift`; the duplication is
/// intentional per the v1 layering note (Schema must remain
/// dependency-free of Help).
@usableFromInline
internal protocol _SubcommandOptionalConvertible {
    var _unwrapped: Any? { get }
}

extension Optional: _SubcommandOptionalConvertible {
    @usableFromInline
    internal var _unwrapped: Any? {
        switch self {
        case .none: return nil
        case let .some(value): return value
        }
    }
}
