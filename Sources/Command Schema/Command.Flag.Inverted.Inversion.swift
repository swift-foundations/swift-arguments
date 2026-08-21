extension Command.Flag.Inverted {

    public enum Inversion: Sendable, Hashable, Equatable {

        case prefixedNo

        case prefixedEnableDisable
    }
}
