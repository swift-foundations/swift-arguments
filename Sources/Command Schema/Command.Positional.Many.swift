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

extension Command.Positional {
    /// A KeyPath-bound array-positional argument declaration.
    ///
    /// `Command.Positional.Many` is the variadic-positional sibling of
    /// ``Command/Positional`` for argv layouts that collect any number of
    /// values into an array field, such as `mycli file1 file2 file3 …`. The
    /// schema parser appends each consumed positional value to the
    /// `WritableKeyPath<Root, [V]>` target rather than overwriting a
    /// single-value slot.
    ///
    /// The outer generic parameters on ``Command/Positional`` carry
    /// `Root` and `V`; this nested type binds `[V]` on `Root`. A typical
    /// call site:
    ///
    /// ```swift
    /// Command.Positional<MyRoot, String>.Many(\.tags,
    ///     name: "tags",
    ///     help: .init(abstract: "Tag values."))
    /// ```
    ///
    /// For value types the consumer does not own (such as `Foundation.URL`,
    /// third-party types), use the `transform:` overload that drops the
    /// ``Argument/Codable`` requirement and accepts a custom parse
    /// closure.
    ///
    /// ## Arity
    ///
    /// The default arity is ``Argument/Arity/atLeast(0)`` — accept zero
    /// or more positional values (rest-positional shape). Callers needing
    /// at-least-one semantics use ``Argument/Arity/atLeast(1)``; bounded
    /// ranges use ``Argument/Arity/range(_:)`` (such as `.range(1...5)`).
    ///
    /// ## Composition constraints
    ///
    /// The L3 schema permits AT MOST ONE ``Command/Positional/Many`` per
    /// schema. A second occurrence creates ambiguous greedy consumption
    /// (which one swallows which tokens?). When mixed with single
    /// ``Command/Positional`` siblings, the rule is "exactly one Many,
    /// and it MUST come last in declaration order." The parse visitor
    /// rejects violations with
    /// ``Command/Error/validationFailed(reason:)``.
    public struct Many: Sendable
    where Root: Sendable, V: Sendable & Equatable {
        /// The KeyPath into the array field on `Root` where parsed values
        /// are appended in argv order.
        public let keyPath: WritableKeyPath<Root, [V]> & Sendable

        /// The L1 declaration carrying name / arity / visibility / help.
        public let declaration: Argument.Positional<V>

        /// Type-erased argv-string parse closure.
        ///
        /// Either the ``Argument/Codable``-driven default
        /// (`{ V(argument: $0) }`) or a custom-`transform:` wrapper that
        /// catches any thrown ``Command/Error`` and returns `nil`.
        @usableFromInline
        internal let parse: @Sendable (String) -> V?

        /// Creates a KeyPath-bound array-positional declaration parsed
        /// via ``Argument/Codable``.
        ///
        /// - Parameters:
        ///   - keyPath: The Root array field where parsed values are
        ///     appended.
        ///   - name: The schema-side identifier (defaults to `"values"`).
        ///   - placeholder: The usage-line placeholder (defaults to `name`).
        ///   - arity: Cardinality. Defaults to
        ///     ``Argument/Arity/atLeast(0)`` (zero or more, rest-positional).
        ///   - visibility: Whether the positional appears in help.
        ///     Defaults to ``Argument/Visibility/visible``.
        ///   - help: Documentation. Defaults to empty.
        @inlinable
        public init(
            _ keyPath: WritableKeyPath<Root, [V]> & Sendable,
            name: String? = nil,
            placeholder: String? = nil,
            arity: Argument.Arity = .atLeast(0),
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init()
        ) where V: Argument.Codable {
            self.keyPath = keyPath
            let resolvedName = name ?? "values"
            self.declaration = Argument.Positional<V>(
                name: resolvedName,
                placeholder: placeholder ?? resolvedName,
                arity: arity,
                visibility: visibility,
                help: help
            )
            self.parse = { V(argument: $0) }
        }

        /// Creates a KeyPath-bound array-positional declaration parsed
        /// via a custom `transform:` closure.
        ///
        /// Escape hatch for non-``Argument/Codable`` value types. Each
        /// consumed argv positional element is fed through `transform` to
        /// produce one `V`, then appended to the bound `[V]` field.
        ///
        /// - Parameters:
        ///   - keyPath: The Root array field where parsed values are
        ///     appended.
        ///   - name: The schema-side identifier (defaults to `"values"`).
        ///   - placeholder: The usage-line placeholder (defaults to `name`).
        ///   - arity: Cardinality. Defaults to
        ///     ``Argument/Arity/atLeast(0)`` (zero or more, rest-positional).
        ///   - visibility: Whether the positional appears in help.
        ///     Defaults to ``Argument/Visibility/visible``.
        ///   - help: Documentation. Defaults to empty.
        ///   - transform: Closure that converts an argv-element string to
        ///     a `V`; throws ``Command/Error`` on parse failure.
        @inlinable
        public init(
            _ keyPath: WritableKeyPath<Root, [V]> & Sendable,
            name: String? = nil,
            placeholder: String? = nil,
            arity: Argument.Arity = .atLeast(0),
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init(),
            transform: @escaping @Sendable (String) throws(Command.Error) -> V
        ) {
            self.keyPath = keyPath
            let resolvedName = name ?? "values"
            self.declaration = Argument.Positional<V>(
                name: resolvedName,
                placeholder: placeholder ?? resolvedName,
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
