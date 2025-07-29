// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Engine",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "Engine",
            targets: ["Engine"]
        ),
        .library(
            name: "EngineCore",
            targets: ["EngineCore"]
        ),
        .library(
            name: "EngineCoreC",
            targets: ["EngineCoreC"]
        ),
        .library(
            name: "EngineMacros",
            targets: ["EngineMacros"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"602.0.0"),
    ],
    targets: [
        .target(
            name: "Engine",
            dependencies: [
                "EngineCore",
            ]
        ),
        .target(
            name: "EngineCore",
            dependencies: [
                "EngineCoreC",
            ]
        ),
        .target(
            name: "EngineCoreC"
        ),
        .target(
            name: "EngineMacros",
            dependencies: [
                "Engine",
                "EngineMacrosCore",
            ]
        ),
        .macro(
            name: "EngineMacrosCore",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "EngineTests",
            dependencies: [
                "Engine",
                "EngineMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
