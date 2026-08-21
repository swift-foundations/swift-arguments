extension Command {

    public struct Positional<Root, V>: Sendable
    where Root: Sendable, V: Sendable & Equatable {

        public let keyPath: any WritableKeyPath<Root, V> & Sendable

        public let declaration: Argument.Positional<V>

        @usableFromInline
        internal let parse: @Sendable (String) -> V?

        @inlinable
        public init(
            _ keyPath: any WritableKeyPath<Root, V> & Sendable,
            name: String? = nil,
            placeholder: String? = nil,
            arity: Argument.Arity = .exactly(1),
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init()
        ) where V: Argument.Codable {
            self.keyPath = keyPath
            let resolvedName = name ?? "value"
            self.declaration = Argument.Positional<V>(
                name: resolvedName,
                placeholder: placeholder ?? resolvedName,
                arity: arity,
                visibility: visibility,
                help: help
            )
            self.parse = { V(argument: $0) }
        }

        @inlinable
        public init(
            _ keyPath: any WritableKeyPath<Root, V> & Sendable,
            name: String? = nil,
            placeholder: String? = nil,
            arity: Argument.Arity = .exactly(1),
            visibility: Argument.Visibility = .visible,
            help: Argument.Help = .init(),
            transform: @escaping @Sendable (String) throws(Command.Error) -> V
        ) {
            self.keyPath = keyPath
            let resolvedName = name ?? "value"
            self.declaration = Argument.Positional<V>(
                name: resolvedName,
                placeholder: placeholder ?? resolvedName,
                arity: arity,
                visibility: visibility,
                help: help
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
