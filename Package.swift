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
            url: "https://github.com/nathantannar4/Engine/releases/download/0.1.0/EngineCore.xcframework.zip",
            checksum: "3ff4bebe634371cd251601b29dee70f2cec400a299c34d503b713e682912a916"
        ),
        .target(
            name: "Engine",
            dependencies: [
                "EngineCore"
            ]
        )
    ]
)
