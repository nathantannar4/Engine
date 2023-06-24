// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Engine",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "EngineCore",
            targets: ["EngineCore"]
        ),
        .library(
            name: "Engine",
            targets: ["Engine"]
        )
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "EngineCore",
            url: "https://github.com/nathantannar4/Engine/releases/download/0.1.10/EngineCore.xcframework.zip",
            checksum: "1e640b454bd9a626ad725c8ae34c3f2cd0523d5a78ee50794070593136288cef"
        ),
        .target(
            name: "Engine",
            dependencies: [
                "EngineCore"
            ]
        )
    ]
)
