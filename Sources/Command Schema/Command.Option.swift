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
    /// A KeyPath-bound named-option declaration.
    ///
    /// `Command.Option<Root, V>` is the L3 binding-aware wrapper over
    /// the L1 ``Argument/Option`` declaration. It stores:
    ///
    /// - The KeyPath into a `Root` value where the parsed value is written.
    /// - The L1 ``Argument/Option`` carrying name (short / long / both),
    ///   arity, visibility, help, optional env-var-fallback metadata.
    /// - A type-erased argv-string parse closure produced by the chosen
    ///   initializer — either the ``Argument/Codable``-driven default or
    ///   the custom-`transform:` escape hatch for value types the
    ///   consumer does not own.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Codable-driven (standard) form:
    /// Command.Option(\.count, name: .long("count"),
    ///                 help: .init(abstract: "Number of repetitions."))
    ///
    /// // Transform-closure (escape hatch) form for a non-Codable type:
    /// Command.Option(\.url, name: .long(.literal("url")), transform: { string in
    ///     guard let parsed = URL(string: string) else {
    ///         throw Command.Error.invalidValue(
    ///             name: "--url",
    ///             value: string,
    ///             position: .init(argvIndex: .zero, byteOffset: .zero)
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
    /// `transform:` overload drops the requirement so consumers can bind
    /// any `Sendable & Equatable` value type through a custom parse
    /// closure.
    public struct Option<Root, V>: Sendable
    where Root: Sendable, V: Sendable & Equatable {
        /// The KeyPath into `Root` where the parsed value is written.
        public let keyPath: WritableKeyPath<Root, V> & Sendable

        /// The L1 declaration carrying name / arity / visibility / help.
        public let declaration: Argument.Option<V>

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

        /// Creates a KeyPath-bound option declaration parsed via
        /// ``Argument/Codable``.
        ///
        /// - Parameters:
        ///   - keyPath: The Root field this option writes to.
        ///   - name: The option name (short / long / both) at the L1
        ///     ``Argument/Name`` level.
        ///   - placeholder: The usage-line placeholder. When `nil`, falls
        ///     back to the option's long-form name or `"value"`.
        ///   - arity: Cardinality. Defaults to `.exactly(1)`.
        ///   - visibility: Whether the option appears in help. Defaults
        ///     to `.visible`.
        ///   - help: Documentation. Defaults to empty.
        ///   - environment: Optional env-var fallback. Defaults
        ///     to `nil`.
        @inlinable
        public init(
            _ keyPath: WritableKeyPath<Root, V> & Sendable,
            name: Argument.Name,
            placeholder: String? = nil,
            arity: Argument.Arity = .exactly(1),
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init(),
            environment: Argument.Environment.Variable.Name? = nil
        ) where V: Argument.Codable {
            self.keyPath = keyPath
            let resolvedValueName = placeholder ?? name.long?.string ?? "value"
            self.declaration = Argument.Option<V>(
                name: name,
                placeholder: resolvedValueName,
                arity: arity,
                visibility: visibility,
                help: help,
                environment: environment
            )
            self.parse = { V(argument: $0) }
        }

        /// Creates a KeyPath-bound option declaration parsed via a custom
        /// `transform:` closure.
        ///
        /// This overload is the escape hatch for value types the consumer
        /// does not own (such as `Foundation.URL`, third-party types) — types
        /// that cannot be retrofitted with an ``Argument/Codable``
        /// conformance because the consumer does not own the type
        /// definition. The closure converts an argv-element string into a
        /// `V`; throwing ``Command/Error`` signals a parse failure that
        /// the parse visitor reports as
        /// ``Command/Error/invalidValue(name:value:position:)`` with the
        /// option's public name (`--long` form or `-short`) and the
        /// offending token's `position`.
        ///
        /// - Parameters:
        ///   - keyPath: The Root field this option writes to.
        ///   - name: The option name (short / long / both) at the L1
        ///     ``Argument/Name`` level.
        ///   - placeholder: The usage-line placeholder. When `nil`, falls
        ///     back to the option's long-form name or `"value"`.
        ///   - arity: Cardinality. Defaults to `.exactly(1)`.
        ///   - visibility: Whether the option appears in help. Defaults
        ///     to `.visible`.
        ///   - help: Documentation. Defaults to empty.
        ///   - environment: Optional env-var fallback. Defaults
        ///     to `nil`. When supplied, the env-var value is also routed
        ///     through `transform`, and a thrown ``Command/Error`` is
        ///     surfaced as
        ///     ``Command/Error/invalidEnvironmentValue(name:environment:value:)``.
        ///   - transform: Closure that converts an argv-element string to
        ///     a `V`; throws ``Command/Error`` on parse failure.
        @inlinable
        public init(
            _ keyPath: WritableKeyPath<Root, V> & Sendable,
            name: Argument.Name,
            placeholder: String? = nil,
            arity: Argument.Arity = .exactly(1),
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init(),
            environment: Argument.Environment.Variable.Name? = nil,
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
                environment: environment
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
