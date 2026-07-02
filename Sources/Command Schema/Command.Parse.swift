// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-arguments open source project
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp and the swift-arguments project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

extension Command {
    /// Parses an argv `[String]` into an initialized `C` command instance.
    ///
    /// `Command.parse(_:from:)` is the L3 entry point for argv parsing.
    /// It composes:
    ///
    /// 1. The L3 ``Argument/Tokenizer/Default`` (POSIX 12.2 short-flag
    ///    forms via ``IEEE_1003/UtilitySyntax/Tokenizer`` + inline GNU
    ///    long options).
    /// 2. A schema-driven L1-token walker that consults
    ///    `C.schema` and writes parsed values into the command instance
    ///    via the KeyPaths stored in each ``Command/Schema/Node``.
    ///
    /// ## Defaults
    ///
    /// The `initial` parameter is the seed `C` instance whose default
    /// field values supply any non-specified option or flag values. Most
    /// callers construct a `C()`-shaped default via a synthesized
    /// memberwise initializer. The schema-driven parser only writes the
    /// fields named in argv; unwritten fields retain their `initial`
    /// values.
    ///
    /// - Parameters:
    ///   - type: The conforming command type.
    ///   - argv: The raw argv (program-name prefix removed).
    ///   - initial: A seed instance carrying default field values for
    ///     non-specified arguments.
    /// - Returns: The fully populated command instance.
    /// - Throws: ``Command/Error`` if argv tokenization or schema-driven
    ///   parsing fails.
    public static func parse<C: `Protocol`>(
        _ type: C.Type,
        from argv: [String],
        initial: C
    ) throws(Error) -> C {
        // Tokenize argv → [Argument.Token].
        let tokens = try Argument.Tokenizer.Default().tokenize(argv)

        // Walk the schema, applying tokens to a mutable copy of `initial`.
        // The argv-aware initializer threads the raw argv and root
        // command name so subcommand dispatch can slice the source
        // argv at the matched subcommand-name boundary and render
        // per-subcommand help with a sensible USAGE line.
        var visitor = Self.Schema.ParseVisitor<C>(
            tokens: tokens,
            argv: argv,
            rootName: C.configuration.name,
            rootVersion: C.configuration.version,
            root: initial
        )
        try C.schema.accept(&visitor)
        // After all schema-bound nodes have been visited, any remaining
        // unconsumed tokens are surplus.
        try visitor.finalize()

        // Post-decode validation hook: conformers SHADOW the
        // extension-default `validate()` to enforce cross-field
        // invariants the schema cannot encode structurally. See
        // ``Command/Protocol/validate()`` for the rationale on
        // extension-only (as opposed to protocol-requirement) shape.
        var root = visitor.root
        try root.validate()
        return root
    }
}
