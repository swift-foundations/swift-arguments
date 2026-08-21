public import Argument_Primitives

extension Argument {

    public protocol Serializable: Sendable {

        var argumentDescription: String { get }
    }
}
