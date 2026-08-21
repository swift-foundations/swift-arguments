extension Command {

    public struct Option<Root, V>: Sendable
    where Root: Sendable, V: Sendable & Equatable {

        public let keyPath: any WritableKeyPath<Root, V> & Sendable

        public let declaration: Argument.Option<V>

        @usableFromInline
        internal let parse: @Sendable (String) -> V?

        @inlinable
        public init(
            _ keyPath: any WritableKeyPath<Root, V> & Sendable,
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

        @inlinable
        public init(
            _ keyPath: any WritableKeyPath<Root, V> & Sendable,
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
