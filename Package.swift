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
//        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "EngineCore",
            targets: ["EngineCore"]
        ),
        .library(
            name: "Engine",
            targets: ["Engine"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .binaryTarget(
            name: "EngineCore",
            url: "https://github.com/nathantannar4/Engine/releases/download/1.1.0/EngineCore.xcframework.zip",
            checksum: "ab337b25cbdf553e576367f5f3c762e4f20eeaf4e8c3bc11480e5cef37de74aa"
        ),
        .target(
            name: "Engine",
            dependencies: [
                "EngineCore",
                "EngineMacros",
            ]
        ),
        .macro(
            name: "EngineMacros",
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
