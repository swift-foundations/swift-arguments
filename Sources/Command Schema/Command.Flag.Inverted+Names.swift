extension Command.Flag.Inverted {

    @inlinable
    public var trueName: String {
        switch inversion {
        case .prefixedNo:
            return base.string

        case .prefixedEnableDisable:
            return "enable-" + base.string
        }
    }

    @inlinable
    public var falseName: String {
        switch inversion {
        case .prefixedNo:
            return "no-" + base.string

        case .prefixedEnableDisable:
            return "disable-" + base.string
        }
    }
}
