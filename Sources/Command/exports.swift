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

// Umbrella target per [MOD-005] — re-exports every sub-target. Downstream
// consumers `import Command` to get the full swift-arguments surface,
// including the `Command.main(_:)` runner (via Command Runner). Consumers
// who do not need the runner can import the narrower variants directly
// to avoid the transitive swift-process dependency.
@_exported public import Command_Namespace
@_exported public import Command_Core
@_exported public import Command_Schema
@_exported public import Command_Help
@_exported public import Command_Runner
@_exported public import Argument_Standard_Library_Integration
