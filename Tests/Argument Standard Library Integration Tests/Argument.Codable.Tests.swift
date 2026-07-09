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

@Suite("Argument.Codable stdlib conformances")
struct ArgumentCodableTests {

    // MARK: - Int

    @Test
    func `Int parses valid decimal`() {
        #expect(Int(argument: "42") == 42)
        #expect(Int(argument: "-7") == -7)
        #expect(Int(argument: "0") == 0)
    }

    @Test
    func `Int returns nil for invalid`() {
        #expect(Int(argument: "not-num") == nil)
        #expect(Int(argument: "") == nil)
    }

    @Test
    func `Int round-trips through argumentDescription`() {
        let value = 123
        #expect(Int(argument: value.argumentDescription) == 123)
    }

    // MARK: - UInt / Int32 / Int64

    @Test
    func `UInt parses non-negative`() {
        #expect(UInt(argument: "42") == 42)
        #expect(UInt(argument: "-1") == nil)
    }

    @Test
    func `Int32 parses 32-bit range`() {
        #expect(Int32(argument: "100") == 100)
        #expect(Int32(argument: "-100") == -100)
    }

    @Test
    func `Int64 parses 64-bit range`() {
        #expect(Int64(argument: "9223372036854775000") == 9_223_372_036_854_775_000)
    }

    // MARK: - Bool

    @Test
    func `Bool parses true/false`() {
        #expect(Bool(argument: "true") == true)
        #expect(Bool(argument: "false") == false)
    }

    @Test
    func `Bool returns nil for invalid`() {
        #expect(Bool(argument: "yes") == nil)
        #expect(Bool(argument: "TRUE") == nil)
    }

    // MARK: - String

    @Test
    func `String adopts argv element as-is`() {
        #expect(String(argument: "hello") == "hello")
        #expect(String(argument: "")?.isEmpty == true)
    }

    @Test
    func `String argumentDescription is the string itself`() {
        let s = "hello world"
        #expect(s.argumentDescription == "hello world")
    }

    // MARK: - Double / Float

    @Test
    func `Double parses`() {
        #expect(Double(argument: "3.14") == 3.14)
        #expect(Double(argument: "1e2") == 100.0)
        #expect(Double(argument: "bad") == nil)
    }

    @Test
    func `Float parses`() {
        #expect(Float(argument: "1.5") == 1.5)
        #expect(Float(argument: "bad") == nil)
    }

    // MARK: - D15 Optional conformance

    @Test
    func `Optional<String> parses non-empty string into .some`() {
        // Optional<String>.init?(argument:) returns String??: the outer
        // optional is the protocol's failure-signalling Self?; the inner
        // is the Wrapped value.
        let value: String?? = String?.init(argument: "hello")
        #expect(value == .some(.some("hello")))
    }

    @Test
    func `Optional<String> parses empty string into .some("")`() {
        // Optional<String>.init(argument: "") delegates to
        // String.init(argument:) which never returns nil — even empty
        // strings adopt as-is — so the outer Optional sees .some(""),
        // yielding .some(.some("")) at the schema layer.
        let value: String?? = String?.init(argument: "")
        #expect(value == .some(.some("")))
    }

    @Test
    func `Optional<Int> parses valid number into .some`() {
        let value: Int?? = Int?.init(argument: "42")
        #expect(value == .some(.some(42)))
    }

    @Test
    func `Optional<Int> returns nil for invalid argv`() {
        // Wrapped Int rejects "not-num" → Optional init? returns nil
        // → schema parser surfaces .invalidValue at consumer call site.
        let value: Int?? = Int?.init(argument: "not-num")
        #expect(value == .none)
    }

    @Test
    func `Optional<Bool> parses valid bool into .some`() {
        let value: Bool?? = Bool?.init(argument: "true")
        #expect(value == .some(.some(true)))
    }

    @Test
    func `Optional<Double> parses valid decimal into .some`() {
        let value: Double?? = Double?.init(argument: "3.14")
        #expect(value == .some(.some(3.14)))
    }

    @Test
    func `Optional<Int>.argumentDescription delegates to wrapped when some`() {
        let value: Int? = 42
        #expect(value.argumentDescription == "42")
    }

    @Test
    func `Optional<Int>.argumentDescription is empty when none`() {
        let value: Int? = nil
        #expect(value.argumentDescription.isEmpty)
    }

    @Test
    func `Optional<String>.argumentDescription delegates to wrapped when some`() {
        let value: String? = "hello"
        #expect(value.argumentDescription == "hello")
    }

    @Test
    func `Optional round-trips via Codable composition`() {
        let original: Int? = 99
        let argv = original.argumentDescription
        let parsed: Int?? = Int?.init(argument: argv)
        #expect(parsed == .some(.some(99)))
    }

    @Test
    func `Optional<Int> conforms to Argument.Codable`() {
        // Witness that Optional<Wrapped: Codable>: Codable composes —
        // a function generic on Codable must accept Optional<Int>.
        func acceptsCodable<T: Argument.Codable>(_ type: T.Type) -> String {
            "\(type)"
        }
        let typeName = acceptsCodable(Optional<Int>.self)
        #expect(typeName.contains("Optional"))
    }
}
