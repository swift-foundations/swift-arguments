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

/// F-001 — "Root-level option/flag values are parsed then silently
/// discarded when a subcommand dispatches."
///
/// Before the fix, `Command.parse(RootFlagWithGroup.self, ...)` would
/// succeed and silently drop the root-level `--verbose` value the
/// moment subcommand dispatch replaced `root` wholesale. After the fix,
/// `Command.Schema.ParseVisitor.finalize()` rejects the schema shape
/// itself — a root-level KeyPath-bound node combined with a
/// `Command.Subcommand.Group` — with `.validationFailed` before argv is
/// even inspected.
extension Command {
    @Suite
    struct `Root Level Group Validation` {

        @Test
        func `Root-level flag combined with Subcommand.Group throws .validationFailed`() {
            do throws(Command.Error) {
                _ = try Command.parse(
                    RootFlagWithGroup.self,
                    from: ["--verbose", "child"],
                    initial: RootFlagWithGroup()
                )
                Issue.record("Expected .validationFailed, parse succeeded")
            } catch {
                switch error {
                case .validationFailed:
                    break  // expected

                default:
                    Issue.record("Expected .validationFailed, got \(error)")
                }
            }
        }

        @Test
        func `Rejection fires even when argv omits the root-level flag`() {
            // The schema-shape violation is unconditional — it does not
            // depend on whether argv actually supplies the root-level
            // flag. Declaring the incompatible shape is itself the fault.
            do throws(Command.Error) {
                _ = try Command.parse(
                    RootFlagWithGroup.self,
                    from: ["child"],
                    initial: RootFlagWithGroup()
                )
                Issue.record("Expected .validationFailed, parse succeeded")
            } catch {
                switch error {
                case .validationFailed:
                    break  // expected

                default:
                    Issue.record("Expected .validationFailed, got \(error)")
                }
            }
        }
    }
}
