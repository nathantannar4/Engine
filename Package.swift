// swift-tools-version: 6.0

import Foundation
import PackageDescription
import CompilerPluginSupport

func isXcodeVersionAtLeast(_ versionString: String) -> Bool {
    let env = ProcessInfo.processInfo.environment
    guard let path = env["PATH"] ?? env["SDKROOT"] ?? env["MANPATH"] ?? env["DEVELOPER_DIR"] else { return false }
    let pattern = #"(?i)Xcode[_-]?([0-9]+(?:\.[0-9]+)*)"#
    guard
        let regex = try? NSRegularExpression(pattern: pattern),
        let match = regex.firstMatch(in: path, range: NSRange(path.startIndex..., in: path)),
        let range = Range(match.range(at: 1), in: path)
    else {
        return false
    }
    let detectedVersion = String(path[range])
    let isMatch = detectedVersion.compare(versionString, options: .numeric) != .orderedAscending
    return isMatch
}

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
            name: "EngineExtensions",
            targets: ["EngineExtensions"]
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
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"700.0.0"),
    ],
    targets: [
        .target(
            name: "Engine",
            dependencies: [
                "EngineCore",
            ],
            swiftSettings: {
                var settings = [SwiftSetting]()
                #if compiler(>=6.2)
                settings.append(.define("XCODE_26"))
                #endif
                #if compiler(>=6.4)
                settings.append(.define("XCODE_27"))
                if isXcodeVersionAtLeast("27.1") {
                    settings.append(.define("XCODE_27_1"))
                }
                #endif
                return settings
            }()
        ),
        .target(
            name: "EngineExtensions",
            dependencies: [
                "Engine",
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
                .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "EngineTests",
            dependencies: [
                "Engine",
                "EngineMacros",
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "EngineTestsBenchmarks",
            dependencies: [
                "Engine",
                "EngineMacros",
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
