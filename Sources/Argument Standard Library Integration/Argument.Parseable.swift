public import Argument_Primitives

extension Argument {

    public protocol Parseable: Sendable {

        init?(argument: String)
    }
}
