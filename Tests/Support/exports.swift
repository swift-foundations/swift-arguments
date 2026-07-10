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

@_exported public import Argument_Primitives_Test_Support
// Test Support spine per [MOD-024].
//
// Anchors on the lowest in-scope Test Support modules — `Argument
// Primitives Test Support` (L1) and `IEEE_1003 Test Support` (L2) — so
// that test files inherit the spine's Tagged-SLI ergonomics and L1
// recording-visitor fixtures via the re-export chain.
@_exported public import Command
@_exported public import IEEE_1003_Test_Support
