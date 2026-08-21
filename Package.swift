// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-arguments",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [

        .library(
            name: "Command Primitive",
            targets: ["Command Primitive"]
        ),

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

        .library(
            name: "Command",
            targets: ["Command"]
        ),

        .library(
            name: "Command Test Support",
            targets: ["Command Test Support"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-primitives/swift-argument-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-affine-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-index-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-text-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-ordinal-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-tagged-primitives.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-ieee/swift-ieee-1003.git", branch: "main"),
        .package(
            url: "https://github.com/swift-primitives/swift-parser-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-serializer-primitives.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-foundations/swift-environment.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-process.git", branch: "main"),
    ],
    targets: [

        .target(
            name: "Command Primitive",
            dependencies: []
        ),

        .target(
            name: "Argument Standard Library Integration",
            dependencies: [
                .product(name: "Argument Primitives", package: "swift-argument-primitives")
            ]
        ),

        .target(
            name: "Command Core",
            dependencies: [
                "Command Primitive",
                "Argument Standard Library Integration",
                .product(name: "Argument Primitives", package: "swift-argument-primitives"),
                .product(name: "Text Primitives", package: "swift-text-primitives"),
                .product(name: "Ordinal Primitive", package: "swift-ordinal-primitives"),
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
                .product(name: "IEEE_1003", package: "swift-ieee-1003"),
                .product(name: "Parser Primitives", package: "swift-parser-primitives"),
                .product(name: "Serializer Primitives", package: "swift-serializer-primitives"),
            ]
        ),

        .target(
            name: "Command Schema",
            dependencies: [
                "Command Core",
                "Argument Standard Library Integration",
                .product(name: "Argument Schema Primitives", package: "swift-argument-primitives"),
                .product(name: "Affine Carrier Primitives", package: "swift-affine-primitives"),
                .product(name: "Affine Tagged Primitives", package: "swift-affine-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Ordinal Primitive", package: "swift-ordinal-primitives"),
                .product(name: "Ordinal Tagged Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
                .product(name: "Text Primitives", package: "swift-text-primitives"),
                .product(name: "Environment", package: "swift-environment"),
            ]
        ),

        .target(
            name: "Command Help",
            dependencies: [
                "Command Schema",
                .product(name: "Serializer Primitives", package: "swift-serializer-primitives"),
            ]
        ),

        .target(
            name: "Command Runner",
            dependencies: [
                "Command Core",
                "Command Schema",
                "Command Help",
                .product(name: "Process", package: "swift-process"),
            ]
        ),

        .target(
            name: "Command",
            dependencies: [
                "Command Primitive",
                "Command Core",
                "Command Schema",
                "Command Help",
                "Command Runner",
                "Argument Standard Library Integration",
            ]
        ),

        .target(
            name: "Command Test Support",
            dependencies: [
                "Command",
                .product(
                    name: "Argument Primitives Test Support",
                    package: "swift-argument-primitives"
                ),
                .product(name: "IEEE_1003 Test Support", package: "swift-ieee-1003"),
                .product(name: "Environment", package: "swift-environment"),
            ],
            path: "Tests/Support",
            exclude: ["Runner Helper"]
        ),

        .executableTarget(
            name: "command-runner-helper",
            dependencies: ["Command"],
            path: "Tests/Support/Runner Helper"
        ),

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
            dependencies: [
                "Command Test Support",

                "command-runner-helper",
                .product(name: "Process", package: "swift-process"),
            ]
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
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
