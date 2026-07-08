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

extension Command.Option {
    /// A KeyPath-bound repeatable-option declaration.
    ///
    /// `Command.Option.Many` is the repeatable-option sibling of
    /// ``Command/Option`` for argv layouts that accept the same option
    /// multiple times, such as `mycli --tag a --tag b --tag c`. Each
    /// occurrence appends one parsed value to the
    /// `WritableKeyPath<Root, [V]>` target rather than overwriting a
    /// single-value slot.
    ///
    /// A typical call site:
    ///
    /// ```swift
    /// Command.Option<MyRoot, String>.Many(\.tags,
    ///     name: .long(.literal("tag")),
    ///     help: .init(abstract: "A tag value (repeatable)."))
    /// ```
    ///
    /// For value types the consumer does not own (such as `Foundation.URL`,
    /// third-party types), use the `transform:` overload that drops the
    /// ``Argument/Codable`` requirement and accepts a custom parse
    /// closure.
    ///
    /// ## Arity
    ///
    /// No arity bound is enforced by default — any number of occurrences
    /// is allowed. Callers needing bounded repetition supply an explicit
    /// ``Argument/Arity`` (such as `.atLeast(1)`, `.range(1...5)`).
    ///
    /// ## Environment-variable fallback
    ///
    /// `environment` fallback for repeatable options is deferred
    /// to v2 — the splitting semantics (comma-separated single value
    /// versus repeated env reads) are not yet defined. Setting
    /// `environment` on a ``Command/Option/Many`` is a no-op at
    /// the v1 surface; the schema author should leave it `nil`.
    public struct Many: Sendable
    where Root: Sendable, V: Sendable & Equatable {
        /// The KeyPath into the array field on `Root` where parsed values
        /// are appended on each occurrence.
        public let keyPath: WritableKeyPath<Root, [V]> & Sendable

        /// The L1 declaration carrying name / arity / visibility / help.
        public let declaration: Argument.Option<V>

        /// Type-erased argv-string parse closure.
        ///
        /// Either the ``Argument/Codable``-driven default
        /// (`{ V(argument: $0) }`) or a custom-`transform:` wrapper that
        /// catches any thrown ``Command/Error`` and returns `nil`.
        @usableFromInline
        internal let parse: @Sendable (String) -> V?

        /// Creates a KeyPath-bound repeatable-option declaration parsed
        /// via ``Argument/Codable``.
        ///
        /// - Parameters:
        ///   - keyPath: The Root array field where parsed values are
        ///     appended on each occurrence.
        ///   - name: The option name (short / long / both) at the L1
        ///     ``Argument/Name`` level.
        ///   - placeholder: The usage-line placeholder. When `nil`, falls
        ///     back to the option's long-form name or `"value"`.
        ///   - arity: Cardinality. Defaults to
        ///     ``Argument/Arity/atLeast(0)`` (any number of occurrences).
        ///   - visibility: Whether the option appears in help. Defaults
        ///     to ``Argument/Visibility/visible``.
        ///   - help: Documentation. Defaults to empty.
        @inlinable
        public init(
            _ keyPath: WritableKeyPath<Root, [V]> & Sendable,
            name: Argument.Name,
            placeholder: String? = nil,
            arity: Argument.Arity = .atLeast(0),
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init()
        ) where V: Argument.Codable {
            self.keyPath = keyPath
            let resolvedValueName = placeholder ?? name.long?.string ?? "value"
            self.declaration = Argument.Option<V>(
                name: name,
                placeholder: resolvedValueName,
                arity: arity,
                visibility: visibility,
                help: help,
                environment: nil
            )
            self.parse = { V(argument: $0) }
        }

        /// Creates a KeyPath-bound repeatable-option declaration parsed
        /// via a custom `transform:` closure.
        ///
        /// Escape hatch for non-``Argument/Codable`` value types. Each
        /// argv occurrence's value is fed through `transform` to produce
        /// one `V`, then appended to the bound `[V]` field.
        ///
        /// - Parameters:
        ///   - keyPath: The Root array field where parsed values are
        ///     appended on each occurrence.
        ///   - name: The option name (short / long / both) at the L1
        ///     ``Argument/Name`` level.
        ///   - placeholder: The usage-line placeholder. When `nil`, falls
        ///     back to the option's long-form name or `"value"`.
        ///   - arity: Cardinality. Defaults to
        ///     ``Argument/Arity/atLeast(0)`` (any number of occurrences).
        ///   - visibility: Whether the option appears in help. Defaults
        ///     to ``Argument/Visibility/visible``.
        ///   - help: Documentation. Defaults to empty.
        ///   - transform: Closure that converts an argv-element string to
        ///     a `V`; throws ``Command/Error`` on parse failure.
        @inlinable
        public init(
            _ keyPath: WritableKeyPath<Root, [V]> & Sendable,
            name: Argument.Name,
            placeholder: String? = nil,
            arity: Argument.Arity = .atLeast(0),
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init(),
            transform: @escaping @Sendable (String) throws(Command.Error) -> V
        ) {
            self.keyPath = keyPath
            let resolvedValueName = placeholder ?? name.long?.string ?? "value"
            self.declaration = Argument.Option<V>(
                name: name,
                placeholder: resolvedValueName,
                arity: arity,
                visibility: visibility,
                help: help,
                environment: nil
            )
            self.parse = { input in
                do throws(Command.Error) {
                    return try transform(input)
                } catch {
                    return nil
                }
            }
        }
    }
}
