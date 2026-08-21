public import Argument_Primitives
public import IEEE_1003
internal import Ordinal_Primitive
internal import Tagged_Primitives
internal import Text_Primitives

extension Argument.Tokenizer {

    public struct Default: Sendable {

        @inlinable
        public init() {}
    }
}

extension Argument.Tokenizer.Default {

    public func tokenize(_ argv: [String]) throws(Command.Error) -> [Argument.Token] {
        var tokens: [Argument.Token] = []
        var byteOffset: Swift.Int = 0
        var afterEndOfOptions = false

        for (argvIndex, element) in argv.enumerated() {
            let elementByteCount = element.utf8.count
            let elementStart = Text.Position(_unchecked: Ordinal(Swift.UInt(byteOffset)))
            let elementEnd = Text.Position(
                _unchecked: Ordinal(Swift.UInt(byteOffset + elementByteCount))
            )
            let elementRange = Text.Range(start: elementStart, end: elementEnd)
            defer { byteOffset += elementByteCount }

            if afterEndOfOptions {
                tokens.append(.init(kind: .positional(element), range: elementRange))
                continue
            }

            if element == "--" {
                tokens.append(.init(kind: .endOfOptions, range: elementRange))
                afterEndOfOptions = true
                continue
            }

            if element.hasPrefix("--"), element.count > 2 {
                let afterDoubleDash = element.dropFirst(2)
                if let equalsIndex = afterDoubleDash.firstIndex(of: "=") {
                    let name = Swift.String(afterDoubleDash[..<equalsIndex])
                    let value = Swift.String(
                        afterDoubleDash[afterDoubleDash.index(after: equalsIndex)...]
                    )

                    tokens.append(.init(kind: .long(name), range: elementRange))
                    tokens.append(.init(kind: .value(value), range: elementRange))
                } else {
                    let name = Swift.String(afterDoubleDash)
                    tokens.append(.init(kind: .long(name), range: elementRange))
                }
                continue
            }

            var oneElementArgv: [Swift.String] = [element]
            let l2Tokens: [IEEE_1003.UtilitySyntax.Token]
            do throws(IEEE_1003.UtilitySyntax.Error) {
                l2Tokens = try IEEE_1003.UtilitySyntax.Tokenizer().parse(&oneElementArgv)
            } catch {
                throw .tokenizer(reason: "\(error)", argvIndex: argvIndex)
            }
            for l2Token in l2Tokens {
                tokens.append(.init(kind: Self.map(l2Kind: l2Token.kind), range: elementRange))
            }
        }

        return tokens
    }

    @inlinable
    package static func map(
        l2Kind: IEEE_1003.UtilitySyntax.Token.Kind
    ) -> Argument.Token.Kind {
        switch l2Kind {
        case .shortFlag(let character):
            return .shortCluster(Swift.String(character))

        case .shortValue(let string):
            return .value(string)

        case .shortCluster(let string):
            return .shortCluster(string)

        case .operand(let string):
            return .positional(string)

        case .endOfOptions:
            return .endOfOptions
        }
    }
}
