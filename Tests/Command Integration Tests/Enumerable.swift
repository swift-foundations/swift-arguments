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

import Command_Test_Support
import Finite_Primitives_Core

/// Mutually exclusive operation enum mapping each case to a long-option name.
enum Operation: Argument.Flag.Enumerable {
    case add
    case multiply
    case divide

    static func name(for value: Self) -> Argument.Name.Long {
        switch value {
        case .add: return .literal("add")
        case .multiply: return .literal("multiply")
        case .divide: return .literal("divide")
        }
    }

    static func help(for value: Self) -> Argument.Help {
        switch value {
        case .add: return .init(abstract: "Add operands.")
        case .multiply: return .init(abstract: "Multiply operands.")
        case .divide: return .init(abstract: "Divide operands.")
        }
    }
}

/// Fixture for Command.Flag.Enumerable.
struct Calculator: Command.`Protocol`, Equatable {
    var operation: Operation

    init(operation: Operation = .add) {
        self.operation = operation
    }

    static var configuration: Command.Configuration {
        Command.Configuration(name: "calculator", abstract: "Enumerable-flag demo.")
    }

    static var schema: Command.Schema.Definition<Self> {
        Command.Schema.Definition<Self> {
            Command.Flag<Self>.Enumerable<Operation>(
                \.operation,
                help: .init(abstract: "Operation:")
            )
        }
    }

    mutating func run() async throws(Command.Error) {}
}
