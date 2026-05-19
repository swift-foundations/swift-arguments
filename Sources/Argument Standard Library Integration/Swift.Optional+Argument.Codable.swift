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

/// `Optional<T>` is parseable + serializable when `T` is parseable +
/// serializable; composing the two sibling conformances gives
/// `Optional<T>: Argument.Codable`. This empty conditional conformance
/// records the protocol-level inheritance — the requirements themselves
/// land on the two sibling-conformance files
/// (``Swift.Optional+Argument.Parseable`` and
/// ``Swift.Optional+Argument.Serializable``).
extension Swift.Optional: Argument.Codable where Wrapped: Argument.Codable {}
