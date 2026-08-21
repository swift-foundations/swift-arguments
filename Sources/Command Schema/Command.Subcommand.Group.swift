extension Command.Subcommand {

    public struct Group<Root: Sendable>: Sendable {

        public let bindings: [any Command.Subcommand.Binding<Root>]

        @inlinable
        public init(bindings: [any Command.Subcommand.Binding<Root>]) {
            Self.checkAtMostOneDefault(bindings)
            self.bindings = bindings
        }

        @inlinable
        public init(
            @Builder _ build: () -> [any Command.Subcommand.Binding<Root>]
        ) {
            let bindings = build()
            Self.checkAtMostOneDefault(bindings)
            self.bindings = bindings
        }

        @inlinable
        package static func checkAtMostOneDefault(
            _ bindings: [any Command.Subcommand.Binding<Root>]
        ) {
            let defaults = bindings.filter(\.isDefault)
            guard defaults.count <= 1 else {
                let names = defaults.map(\.name).joined(separator: ", ")
                preconditionFailure(
                    "Command.Subcommand.Group declares more than one default subcommand: \(names). "
                        + "At most one Case may carry .default per Group."
                )
            }
        }
    }
}
