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

// Argument Standard Library Integration carries the L3-resident sibling
// format-Codable protocols (Argument.Codable / .Parseable / .Serializable)
// and stdlib conformances per [FAM-009] hybrid placement rule. Re-export
// L1 `Argument Primitives` so downstream consumers importing this target
// get the full L1 Argument vocabulary alongside the conformances.
@_exported public import Argument_Primitives
