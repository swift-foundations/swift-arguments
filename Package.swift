// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-arguments",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        // MARK: - Namespace
        .library(
            name: "Command Namespace",
            targets: ["Command Namespace"]
        ),

        // MARK: - Core + Variants
        .library(
            name: "Command Core",
            targets: ["Command Core"]
        ),
        .library(
            name: "Command Schema",
            targets: ["Command Schema"]
        ),
        .library(
            name: "Command Help",
            targets: ["Command Help"]
        ),
        .library(
            name: "Command Runner",
            targets: ["Command Runner"]
        ),
        .library(
            name: "Argument Standard Library Integration",
            targets: ["Argument Standard Library Integration"]
        ),

        // MARK: - Umbrella
        .library(
            name: "Command",
            targets: ["Command"]
        ),

        // MARK: - Test Support
        .library(
            name: "Command Test Support",
            targets: ["Command Test Support"]
        ),
    ],
    dependencies: [
        .package(path: "../../swift-primitives/swift-argument-primitives"),
        .package(path: "../../swift-standards/swift-ieee-1003"),
        .package(path: "../../swift-primitives/swift-parser-primitives"),
        .package(path: "../../swift-primitives/swift-serializer-primitives"),
        .package(path: "../swift-environment"),
        .package(path: "../swift-process"),
    ],
    targets: [
        // MARK: - Namespace
        .target(
            name: "Command Namespace",
            dependencies: []
        ),

        // MARK: - Argument Standard Library Integration
        // Per [FAM-009] hybrid placement rule: Argument.Codable / Parseable /
        // Serializable sibling protocols + stdlib conformances live at L3
        // (relocated from L1 due to [PRIM-FOUND-004] substrate-friction).
        .target(
            name: "Argument Standard Library Integration",
            dependencies: [
                .product(name: "Argument Primitives", package: "swift-argument-primitives"),
            ]
        ),

        // MARK: - Core
        // Owns Command.`Protocol`, Configuration, Error, Context, Exit, plus
        // the L3 argv-tokenizer composition (IEEE_1003 + inline GNU long
        // options per §3.4 v1.0.7).
        .target(
            name: "Command Core",
            dependencies: [
                "Command Namespace",
                "Argument Standard Library Integration",
                .product(name: "Argument Primitives", package: "swift-argument-primitives"),
                .product(name: "IEEE_1003", package: "swift-ieee-1003"),
                .product(name: "Parser Primitives", package: "swift-parser-primitives"),
                .product(name: "Serializer Primitives", package: "swift-serializer-primitives"),
            ]
        ),

        // MARK: - Schema (L3 binding-aware schema with KeyPath value-writers)
        .target(
            name: "Command Schema",
            dependencies: [
                "Command Core",
                "Argument Standard Library Integration",
                .product(name: "Argument Schema Primitives", package: "swift-argument-primitives"),
                .product(name: "Environment", package: "swift-environment"),
            ]
        ),

        // MARK: - Help (Serializer.`Protocol` over Command.Schema.Definition)
        .target(
            name: "Command Help",
            dependencies: [
                "Command Schema",
                .product(name: "Serializer Primitives", package: "swift-serializer-primitives"),
            ]
        ),

        // MARK: - Runner
        // Hosts `Command.main(_:initial:arguments:)` — the opt-in
        // convenience runner that composes parse + run + diagnostic
        // rendering + `Process.exit(_:)`. Isolated from Core / Schema /
        // Help so consumers using only the parsing surface do not
        // transitively pull in swift-process.
        .target(
            name: "Command Runner",
            dependencies: [
                "Command Core",
                "Command Schema",
                "Command Help",
                .product(name: "Process", package: "swift-process"),
            ]
        ),

        // MARK: - Umbrella per [MOD-005]
        .target(
            name: "Command",
            dependencies: [
                "Command Namespace",
                "Command Core",
                "Command Schema",
                "Command Help",
                "Command Runner",
                "Argument Standard Library Integration",
            ]
        ),

        // MARK: - Test Support per [MOD-011] / [MOD-024] spine
        .target(
            name: "Command Test Support",
            dependencies: [
                "Command",
                .product(name: "Argument Primitives Test Support", package: "swift-argument-primitives"),
                .product(name: "IEEE_1003 Test Support", package: "swift-ieee-1003"),
                .product(name: "Environment", package: "swift-environment"),
            ],
            path: "Tests/Support"
        ),

        // MARK: - Tests
        .testTarget(
            name: "Command Core Tests",
            dependencies: ["Command Test Support"]
        ),
        .testTarget(
            name: "Command Schema Tests",
            dependencies: ["Command Test Support"]
        ),
        .testTarget(
            name: "Command Help Tests",
            dependencies: ["Command Test Support"]
        ),
        .testTarget(
            name: "Command Integration Tests",
            dependencies: ["Command Test Support"]
        ),
        .testTarget(
            name: "Argument Standard Library Integration Tests",
            dependencies: ["Command Test Support"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
