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
            url: "https://github.com/nathantannar4/Engine/releases/download/1.0.0/EngineCore.xcframework.zip",
            checksum: "cd8ac3c6ba1882f83e79b67745dcbbd7245bc6c23cab0ee4ea86ed2c32eb84db"
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
