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

import Testing

@testable import Command_Test_Support

@Suite("Command.Schema.Definition")
struct CommandSchemaDefinitionTests {

    fileprivate struct TestRoot: Sendable, Equatable {
        var phrase: String = ""
        var count: Int = 0
        var verbose: Bool = false
    }

    @Test
    func `Builder closure accepts mixed-kind nodes`() {
        let definition = Command.Schema.Definition<TestRoot> {
            Command.Positional(\.phrase, name: "phrase")
            Command.Option(
                \.count,
                name: .longLiteral("count")
            )
            Command.Flag(
                \.verbose,
                name: .longLiteral("verbose")
            )
        }
        #expect(definition.nodes.count == 3)
    }

    @Test
    func `Definition supports empty schemas`() {
        let definition = Command.Schema.Definition<TestRoot>(nodes: [])
        #expect(definition.nodes.isEmpty)
    }

    @Test
    func `Direct-array initializer takes ordered nodes`() {
        let nodes: [any Command.Schema.Node<TestRoot>] = [
            Command.Positional(\.phrase, name: "p"),
            Command.Flag(\.verbose, name: .longLiteral("v")),
        ]
        let definition = Command.Schema.Definition<TestRoot>(nodes: nodes)
        #expect(definition.nodes.count == 2)
    }

    // MARK: - D16 OptionGroup

    fileprivate struct Fragment: Sendable, Equatable {
        var name: String = ""
    }

    fileprivate struct CompositeRoot: Sendable, Equatable {
        var fragment: Fragment = .init()
        var count: Int = 0
    }

    @Test
    func `OptionGroup is a Schema.Node`() {
        // Witnesses Command.OptionGroup: Command.Schema.Node — the
        // builder grammar's `buildExpression` accepts it.
        let definition = Command.Schema.Definition<CompositeRoot> {
            Command.OptionGroup(\.fragment, schema: Fragment.schema)
            Command.Option(\.count, name: .longLiteral("count"))
        }
        #expect(definition.nodes.count == 2)
    }

    @Test
    func `OptionGroup with default visibility`() {
        let group = Command.OptionGroup<CompositeRoot, Fragment>(
            \.fragment,
            schema: Fragment.schema
        )
        #expect(group.visibility == .visible)
    }

    @Test
    func `OptionGroup with explicit hidden visibility`() {
        let group = Command.OptionGroup<CompositeRoot, Fragment>(
            \.fragment,
            schema: Fragment.schema,
            visibility: .hidden
        )
        #expect(group.visibility == .hidden)
    }
}

extension CommandSchemaDefinitionTests.Fragment {
    static let schema: Command.Schema.Definition<Self> = .init {
        Command.Option(\.name, name: .longLiteral("name"))
    }
}
