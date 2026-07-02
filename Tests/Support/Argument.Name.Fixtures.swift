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

extension Argument.Name {
    /// Test-support helper: constructs a `.long(_)` name from a known-good
    /// literal, returning a sentinel name if validation fails.
    ///
    /// The sentinel-on-failure shape avoids `try!` at test call sites
    /// (which the lint rule prohibits). Tests should supply only
    /// literals that satisfy GNU long-option validation; the sentinel
    /// path is a defensive fallback that should never fire in
    /// well-formed tests.
    public static func longLiteral(_ string: Swift.String) -> Argument.Name {
        do {
            return .long(try Self.Long(string))
        } catch {
            return .long(Self.Long(_unchecked: string))
        }
    }

    /// Test-support helper: constructs a `.short(_)` name from a known-good
    /// literal character.
    public static func shortLiteral(_ character: Swift.Character) -> Argument.Name {
        do {
            return .short(try Self.Short(character))
        } catch {
            return .short(Self.Short(_unchecked: character))
        }
    }

    /// Test-support helper: constructs a `.both(short:long:)` name from
    /// known-good literals.
    public static func bothLiteral(short: Swift.Character, long: Swift.String) -> Argument.Name {
        let shortName: Argument.Name.Short
        do {
            shortName = try Self.Short(short)
        } catch {
            shortName = Self.Short(_unchecked: short)
        }
        let longName: Argument.Name.Long
        do {
            longName = try Self.Long(long)
        } catch {
            longName = Self.Long(_unchecked: long)
        }
        return .both(short: shortName, long: longName)
    }
}
