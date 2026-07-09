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

@Suite("Array-typed (.Many) positional and option parse")
struct ManyParseTests {

    // MARK: - Positional.Many

    @Test
    func `Empty argv → empty array (default atLeast(0))`() throws(Command.Error) {
        let parsed = try Command.parse(ManyPositional.self, from: [], initial: ManyPositional())
        #expect(parsed.files == [])
    }

    @Test
    func `Single value → single-element array`() throws(Command.Error) {
        let parsed = try Command.parse(
            ManyPositional.self,
            from: ["foo.txt"],
            initial: ManyPositional()
        )
        #expect(parsed.files == ["foo.txt"])
    }

    @Test
    func `Multiple values → multi-element array in argv order`() throws(Command.Error) {
        let parsed = try Command.parse(
            ManyPositional.self,
            from: ["a", "b", "c", "d"],
            initial: ManyPositional()
        )
        #expect(parsed.files == ["a", "b", "c", "d"])
    }

    // MARK: - Option.Many

    @Test
    func `Zero occurrences → empty array (default atLeast(0))`() throws(Command.Error) {
        let parsed = try Command.parse(ManyOption.self, from: [], initial: ManyOption())
        #expect(parsed.tags == [])
    }

    @Test
    func `Single occurrence`() throws(Command.Error) {
        let parsed = try Command.parse(
            ManyOption.self,
            from: ["--tag", "alpha"],
            initial: ManyOption()
        )
        #expect(parsed.tags == ["alpha"])
    }

    @Test
    func `Multiple occurrences in argv order`() throws(Command.Error) {
        let parsed = try Command.parse(
            ManyOption.self,
            from: ["--tag", "alpha", "--tag", "beta", "--tag", "gamma"],
            initial: ManyOption()
        )
        #expect(parsed.tags == ["alpha", "beta", "gamma"])
    }

    // MARK: - Mixed fixed + rest positional

    @Test
    func `Fixed positional consumed first, rest stream into array`() throws(Command.Error) {
        let parsed = try Command.parse(
            MixedPositionals.self,
            from: ["build", "src", "tests", "docs"],
            initial: MixedPositionals()
        )
        #expect(parsed.command == "build")
        #expect(parsed.arguments == ["src", "tests", "docs"])
    }

    @Test
    func `Fixed positional alone — rest is empty`() throws(Command.Error) {
        let parsed = try Command.parse(
            MixedPositionals.self,
            from: ["run"],
            initial: MixedPositionals()
        )
        #expect(parsed.command == "run")
        #expect(parsed.arguments == [])
    }
}
