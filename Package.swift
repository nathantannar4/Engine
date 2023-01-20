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
            url: "https://github.com/nathantannar4/Engine/releases/download/0.1.4/EngineCore.xcframework.zip",
            checksum: "3746b5786541185598db8baced6dc2bc9a736b598efb55e3fa12ef79591aa5fb"
        ),
        .target(
            name: "Engine",
            dependencies: [
                "EngineCore"
            ]
        )
    ]
)
