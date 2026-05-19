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
    /// A KeyPath-bound positional argument declaration.
    ///
    /// `Command.Positional<Root, V>` is the L3 binding-aware wrapper over
    /// the L1 ``Argument/Positional`` declaration. It stores:
    ///
    /// - The KeyPath into a `Root` value where the parsed value is written.
    /// - The L1 ``Argument/Positional`` carrying name / arity /
    ///   visibility / help metadata for help-text emission.
    /// - A type-erased argv-string parse closure produced by the chosen
    ///   initializer — either the ``Argument/Codable``-driven default
    ///   ``init(_:name:valueName:arity:visibility:help:)`` or the
    ///   custom-`transform:` escape hatch
    ///   ``init(_:name:valueName:arity:visibility:help:transform:)`` for
    ///   value types the consumer does not own (e.g. `Foundation.URL`,
    ///   third-party types) that cannot conform to ``Argument/Codable``.
    ///
    /// The schema-driven parser at ``Command/Core`` consults the KeyPath
    /// to write the parsed value into a `Root` instance; visitors at
    /// ``Command/Schema/Visitor`` walk the declaration metadata for
    /// help-text and completion-script emission.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Codable-driven (standard) form:
    /// Command.Positional(\.phrase, help: .init(abstract: "The phrase to repeat."))
    ///
    /// // Transform-closure (escape hatch) form for a non-Codable type:
    /// Command.Positional(\.url, name: "url", transform: { string in
    ///     guard let parsed = URL(string: string) else {
    ///         throw Command.Error.invalidValue(
    ///             name: "url",
    ///             value: string,
    ///             position: .init(argvIndex: 0, byteOffset: 0)
    ///         )
    ///     }
    ///     return parsed
    /// })
    /// ```
    ///
    /// ## Value-type constraints
    ///
    /// `V` must be `Sendable & Equatable`. The ``Argument/Codable``
    /// conformance is required ONLY by the standard initializer; the
    /// ``init(_:name:valueName:arity:visibility:help:transform:)`` overload
    /// drops the requirement so consumers can bind any `Sendable & Equatable`
    /// value type through a custom parse closure.
    public struct Positional<Root, V>: Sendable
    where Root: Sendable, V: Sendable & Equatable {
        /// The KeyPath into `Root` where the parsed value is written.
        public let keyPath: WritableKeyPath<Root, V> & Sendable

        /// The L1 declaration carrying name / arity / visibility / help.
        public let declaration: Argument.Positional<V>

        /// Type-erased argv-string parse closure. Either:
        ///
        /// - The ``Argument/Codable``-driven default
        ///   (`{ V(argument: $0) }`), set by the standard initializer.
        /// - A custom-`transform:` wrapper that catches any thrown
        ///   ``Command/Error`` and returns `nil` so the parse visitor
        ///   surfaces the standard ``Command/Error/invalidValue(name:value:position:)``
        ///   with the correct name + position context.
        @usableFromInline
        internal let parse: @Sendable (String) -> V?

        /// Creates a KeyPath-bound positional declaration parsed via
        /// ``Argument/Codable``.
        ///
        /// - Parameters:
        ///   - keyPath: The Root field this positional writes to.
        ///   - name: The schema-side identifier. When `nil`, the key-path's
        ///     value-name is derived from a string-describing form
        ///     (intentionally minimal — schema authors typically supply an
        ///     explicit `name`).
        ///   - valueName: The usage-line placeholder. When `nil`, falls
        ///     back to `name`.
        ///   - arity: Cardinality. Defaults to `.exactly(1)`.
        ///   - visibility: Whether the positional appears in help.
        ///     Defaults to `.visible`.
        ///   - help: Documentation. Defaults to empty.
        @inlinable
        public init(
            _ keyPath: WritableKeyPath<Root, V> & Sendable,
            name: String? = nil,
            valueName: String? = nil,
            arity: Argument.Arity = .exactly(1),
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init()
        ) where V: Argument.Codable {
            self.keyPath = keyPath
            let resolvedName = name ?? "value"
            self.declaration = Argument.Positional<V>(
                name: resolvedName,
                valueName: valueName ?? resolvedName,
                arity: arity,
                visibility: visibility,
                help: help
            )
            self.parse = { V(argument: $0) }
        }

        /// Creates a KeyPath-bound positional declaration parsed via a
        /// custom `transform:` closure.
        ///
        /// This overload is the escape hatch for value types the consumer
        /// does not own (e.g. `Foundation.URL`, third-party types) — types
        /// that cannot be retrofitted with an ``Argument/Codable``
        /// conformance because the consumer does not own the type
        /// definition. The closure converts an argv-element string into a
        /// `V`; throwing ``Command/Error`` signals a parse failure that
        /// the parse visitor reports as
        /// ``Command/Error/invalidValue(name:value:position:)`` with the
        /// declaration's `name` and the offending token's `position`.
        ///
        /// - Parameters:
        ///   - keyPath: The Root field this positional writes to.
        ///   - name: The schema-side identifier. When `nil`, falls back
        ///     to `"value"`.
        ///   - valueName: The usage-line placeholder. When `nil`, falls
        ///     back to `name`.
        ///   - arity: Cardinality. Defaults to `.exactly(1)`.
        ///   - visibility: Whether the positional appears in help.
        ///     Defaults to `.visible`.
        ///   - help: Documentation. Defaults to empty.
        ///   - transform: Closure that converts an argv-element string to
        ///     a `V`; throws ``Command/Error`` on parse failure.
        @inlinable
        public init(
            _ keyPath: WritableKeyPath<Root, V> & Sendable,
            name: String? = nil,
            valueName: String? = nil,
            arity: Argument.Arity = .exactly(1),
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init(),
            transform: @escaping @Sendable (String) throws(Command.Error) -> V
        ) {
            self.keyPath = keyPath
            let resolvedName = name ?? "value"
            self.declaration = Argument.Positional<V>(
                name: resolvedName,
                valueName: valueName ?? resolvedName,
                arity: arity,
                visibility: visibility,
                help: help
            )
            self.parse = { input in
                do {
                    return try transform(input)
                } catch {
                    return nil
                }
            }
        }
    }
}
