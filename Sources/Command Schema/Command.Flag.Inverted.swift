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

extension Command.Flag {
    /// A KeyPath-bound inverted boolean-flag declaration registering both
    /// a "true" name and a "false" name pointing at the same field.
    ///
    /// `Command.Flag.Inverted` is the toggle-pair sibling of
    /// ``Command/Flag`` for argv layouts that expose both an "on" and an
    /// explicit "off" long option pointing at the same `Bool` field. A
    /// typical call site:
    ///
    /// ```swift
    /// // Registers --feature / --no-feature
    /// Command.Flag<MyRoot>.Inverted(\.feature,
    ///     base: .literal("feature"),
    ///     inversion: .prefixedNo,
    ///     help: .init(abstract: "Enable the feature."))
    /// ```
    ///
    /// ## Inversion strategies
    ///
    /// See ``Command/Flag/Inverted/Inversion`` for the supported pairs.
    /// The strategy determines how the L3 schema layer derives the two
    /// long-option names from the supplied `base` name.
    ///
    /// ## Semantics
    ///
    /// The schema parser registers two long-option names (the "true"
    /// and "false" forms). Either argv occurrence writes the
    /// corresponding `Bool` value to the bound field. Last occurrence
    /// wins when both forms appear on argv. The bound field's initial
    /// value supplies the value when neither form appears.
    public struct Inverted: Sendable where Root: Sendable {
        /// The KeyPath into `Root` where the resolved `Bool` value is
        /// written when either form appears on argv.
        public let keyPath: WritableKeyPath<Root, Bool> & Sendable

        /// The base long name from which both the "true" and "false"
        /// forms are derived (such as `"feature"` →
        /// `--feature` / `--no-feature`).
        public let base: Argument.Name.Long

        /// The strategy that maps `base` to the two long-option names.
        public let inversion: Inversion

        /// Whether either form appears in help.
        public let visibility: Argument.Visibility

        /// Documentation for the flag pair.
        public let help: Argument.Help

        /// Creates a KeyPath-bound inverted boolean-flag declaration.
        ///
        /// - Parameters:
        ///   - keyPath: The Bool field this flag pair writes to.
        ///   - base: The base long name used to derive both forms (such as
        ///     `"feature"`).
        ///   - inversion: The strategy that maps `base` to the two
        ///     long-option names. Defaults to
        ///     ``Command/Flag/Inverted/Inversion/prefixedNo``.
        ///   - visibility: Whether either form appears in help. Defaults
        ///     to ``Argument/Visibility/visible``.
        ///   - help: Documentation. Defaults to empty.
        @inlinable
        public init(
            _ keyPath: WritableKeyPath<Root, Bool> & Sendable,
            base: Argument.Name.Long,
            inversion: Inversion = .prefixedNo,
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init()
        ) {
            self.keyPath = keyPath
            self.base = base
            self.inversion = inversion
            self.visibility = visibility
            self.help = help
        }
    }
}
