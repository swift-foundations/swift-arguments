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

    @Test("Int parses valid decimal")
    func intParses() {
        #expect(Int(argument: "42") == 42)
        #expect(Int(argument: "-7") == -7)
        #expect(Int(argument: "0") == 0)
    }

    @Test("Int returns nil for invalid")
    func intInvalid() {
        #expect(Int(argument: "not-num") == nil)
        #expect(Int(argument: "") == nil)
    }

    @Test("Int round-trips through argumentDescription")
    func intRoundTrip() {
        let value = 123
        #expect(Int(argument: value.argumentDescription) == 123)
    }

    // MARK: - UInt / Int32 / Int64

    @Test("UInt parses non-negative")
    func uintParses() {
        #expect(UInt(argument: "42") == 42)
        #expect(UInt(argument: "-1") == nil)
    }

    @Test("Int32 parses 32-bit range")
    func int32Parses() {
        #expect(Int32(argument: "100") == 100)
        #expect(Int32(argument: "-100") == -100)
    }

    @Test("Int64 parses 64-bit range")
    func int64Parses() {
        #expect(Int64(argument: "9223372036854775000") == 9_223_372_036_854_775_000)
    }

    // MARK: - Bool

    @Test("Bool parses true/false")
    func boolParses() {
        #expect(Bool(argument: "true") == true)
        #expect(Bool(argument: "false") == false)
    }

    @Test("Bool returns nil for invalid")
    func boolInvalid() {
        #expect(Bool(argument: "yes") == nil)
        #expect(Bool(argument: "TRUE") == nil)
    }

    // MARK: - String

    @Test("String adopts argv element as-is")
    func stringPassesThrough() {
        #expect(String(argument: "hello") == "hello")
        #expect(String(argument: "")?.isEmpty == true)
    }

    @Test("String argumentDescription is the string itself")
    func stringDescription() {
        let s = "hello world"
        #expect(s.argumentDescription == "hello world")
    }

    // MARK: - Double / Float

    @Test("Double parses")
    func doubleParses() {
        #expect(Double(argument: "3.14") == 3.14)
        #expect(Double(argument: "1e2") == 100.0)
        #expect(Double(argument: "bad") == nil)
    }

    @Test("Float parses")
    func floatParses() {
        #expect(Float(argument: "1.5") == 1.5)
        #expect(Float(argument: "bad") == nil)
    }

    // MARK: - D15 Optional conformance

    @Test("Optional<String> parses non-empty string into .some")
    func optionalStringParses() {
        // Optional<String>.init?(argument:) returns String??: the outer
        // optional is the protocol's failure-signalling Self?; the inner
        // is the Wrapped value.
        let value: String?? = String?.init(argument: "hello")
        #expect(value == .some(.some("hello")))
    }

    @Test("Optional<String> parses empty string into .some(\"\")")
    func optionalStringEmptyArgv() {
        // Optional<String>.init(argument: "") delegates to
        // String.init(argument:) which never returns nil — even empty
        // strings adopt as-is — so the outer Optional sees .some(""),
        // yielding .some(.some("")) at the schema layer.
        let value: String?? = String?.init(argument: "")
        #expect(value == .some(.some("")))
    }

    @Test("Optional<Int> parses valid number into .some")
    func optionalIntParses() {
        let value: Int?? = Int?.init(argument: "42")
        #expect(value == .some(.some(42)))
    }

    @Test("Optional<Int> returns nil for invalid argv")
    func optionalIntInvalid() {
        // Wrapped Int rejects "not-num" → Optional init? returns nil
        // → schema parser surfaces .invalidValue at consumer call site.
        let value: Int?? = Int?.init(argument: "not-num")
        #expect(value == .none)
    }

    @Test("Optional<Bool> parses valid bool into .some")
    func optionalBoolParses() {
        let value: Bool?? = Bool?.init(argument: "true")
        #expect(value == .some(.some(true)))
    }

    @Test("Optional<Double> parses valid decimal into .some")
    func optionalDoubleParses() {
        let value: Double?? = Double?.init(argument: "3.14")
        #expect(value == .some(.some(3.14)))
    }

    @Test("Optional<Int>.argumentDescription delegates to wrapped when some")
    func optionalIntDescriptionSome() {
        let value: Int? = 42
        #expect(value.argumentDescription == "42")
    }

    @Test("Optional<Int>.argumentDescription is empty when none")
    func optionalIntDescriptionNone() {
        let value: Int? = nil
        #expect(value.argumentDescription.isEmpty)
    }

    @Test("Optional<String>.argumentDescription delegates to wrapped when some")
    func optionalStringDescriptionSome() {
        let value: String? = "hello"
        #expect(value.argumentDescription == "hello")
    }

    @Test("Optional round-trips via Codable composition")
    func optionalRoundTrip() {
        let original: Int? = 99
        let argv = original.argumentDescription
        let parsed: Int?? = Int?.init(argument: argv)
        #expect(parsed == .some(.some(99)))
    }

    @Test("Optional<Int> conforms to Argument.Codable")
    func optionalCodableConformance() {
        // Witness that Optional<Wrapped: Codable>: Codable composes —
        // a function generic on Codable must accept Optional<Int>.
        func acceptsCodable<T: Argument.Codable>(_ type: T.Type) -> String {
            "\(type)"
        }
        let typeName = acceptsCodable(Optional<Int>.self)
        #expect(typeName.contains("Optional"))
    }
}
