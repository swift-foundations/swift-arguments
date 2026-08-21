extension Command {

    public static func parse<C: `Protocol`>(
        _ type: C.Type,
        from argv: [String],
        initial: C
    ) throws(Error) -> C {

        let tokens = try Argument.Tokenizer.Default().tokenize(argv)

        var visitor = Self.Schema.ParseVisitor<C>(
            tokens: tokens,
            argv: argv,
            rootName: C.configuration.name,
            rootVersion: C.configuration.version,
            root: initial
        )
        try C.schema.accept(&visitor)

        try visitor.finalize()

        var root = visitor.root
        try root.validate()
        return root
    }
}
