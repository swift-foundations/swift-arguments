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

/// The `Command` namespace per [API-NAME-001].
///
/// `Command` is the L3 root namespace for swift-arguments — the institute's
/// argument-parsing foundation. It owns:
///
/// - ``Command/Protocol`` — the single always-async command-conformance
///   protocol per U3 v1.0.4 (no `Command.Async.Protocol`).
/// - ``Command/Configuration`` — static metadata (name, abstract, version,
///   aliases) for one command.
/// - ``Command/Error`` — the typed-throws domain for command-level errors.
/// - ``Command/Context`` — invocation state passed to `run()`.
/// - ``Command/Exit`` — typed exit-code structure.
/// - ``Command/Schema`` — schema-as-data namespace with KeyPath-bound nodes
///   and the `@Command.Builder` result builder.
/// - ``Command/Help`` — `Serializer.Protocol` over a Command schema.
///
/// Per [MOD-017], the namespace target carries no implementation —
/// the dependency invariant is hard.
public enum Command {}
