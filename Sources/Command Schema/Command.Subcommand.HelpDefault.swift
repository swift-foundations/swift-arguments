extension Command.Subcommand {

    @usableFromInline
    internal enum HelpDefault {}
}

extension Command.Subcommand.HelpDefault {

    @usableFromInline
    internal static func inject<Root, V>(
        _ help: Argument.Help,
        initial: Root?,
        keyPath: any WritableKeyPath<Root, V> & Sendable
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

@usableFromInline
internal protocol _SubcommandOptionalConvertible {
    var _unwrapped: Any? { get }
}

extension Optional: _SubcommandOptionalConvertible {
    @usableFromInline
    internal var _unwrapped: Any? {
        switch self {
        case .none: return nil
        case .some(let value): return value
        }
    }
}
