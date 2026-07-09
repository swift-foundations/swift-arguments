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

@Suite("Inverted flag (.Inverted) parse")
struct InvertedParseTests {

    // MARK: - prefixedNo strategy

    @Test
    func `No occurrence → initial value preserved`() throws(Command.Error) {
        let parsed = try Command.parse(FeatureToggle.self, from: [], initial: FeatureToggle())
        #expect(parsed.feature == false)
    }

    @Test
    func `--feature writes true`() throws(Command.Error) {
        let parsed = try Command.parse(
            FeatureToggle.self,
            from: ["--feature"],
            initial: FeatureToggle()
        )
        #expect(parsed.feature == true)
    }

    @Test
    func `--no-feature writes false`() throws(Command.Error) {
        let parsed = try Command.parse(
            FeatureToggle.self,
            from: ["--no-feature"],
            initial: FeatureToggle(feature: true)
        )
        #expect(parsed.feature == false)
    }

    @Test
    func `Last occurrence wins (--feature then --no-feature)`() throws(Command.Error) {
        let parsed = try Command.parse(
            FeatureToggle.self,
            from: ["--feature", "--no-feature"],
            initial: FeatureToggle()
        )
        #expect(parsed.feature == false)
    }

    @Test
    func `Last occurrence wins (--no-feature then --feature)`() throws(Command.Error) {
        let parsed = try Command.parse(
            FeatureToggle.self,
            from: ["--no-feature", "--feature"],
            initial: FeatureToggle()
        )
        #expect(parsed.feature == true)
    }

    // MARK: - prefixedEnableDisable strategy

    @Test
    func `--enable-service writes true`() throws(Command.Error) {
        let parsed = try Command.parse(
            ServiceToggle.self,
            from: ["--enable-service"],
            initial: ServiceToggle()
        )
        #expect(parsed.service == true)
    }

    @Test
    func `--disable-service writes false`() throws(Command.Error) {
        let parsed = try Command.parse(
            ServiceToggle.self,
            from: ["--disable-service"],
            initial: ServiceToggle(service: true)
        )
        #expect(parsed.service == false)
    }
}
