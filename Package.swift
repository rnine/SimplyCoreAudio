// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AMCoreAudio",
    platforms: [.macOS(.v10_10)],
    products: [
        .library(name: "AMCoreAudio", targets: ["AMCoreAudio"])
    ],
    dependencies: [],
    targets: [
        .target(name: "AMCoreAudio", path: "Source"),
        .testTarget(name: "AMCoreAudioTests", dependencies: ["AMCoreAudio"], path: "Tests")
    ],
    swiftLanguageVersions: [.v4, .v4_2, .v5]
)
