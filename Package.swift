// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Engine",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
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
            url: "https://github.com/nathantannar4/Engine/raw/visionOS/Sources/EngineCore.xcframework.zip",
            checksum: "ee9967175086c7caaf21140eb86d7c31f5adf5ef869eff65d9ef7c4b20694beb"
        ),
        .target(
            name: "Engine",
            dependencies: [
                "EngineCore"
            ]
        )
    ]
)
