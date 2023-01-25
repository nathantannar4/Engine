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
            url: "https://github.com/nathantannar4/Engine/releases/download/0.1.5/EngineCore.xcframework.zip",
            checksum: "1e542816e2ef220394c4ec656050ed84736b7d552484ff80a959ecc5007d2af9"
        ),
        .target(
            name: "Engine",
            dependencies: [
                "EngineCore"
            ]
        )
    ]
)
