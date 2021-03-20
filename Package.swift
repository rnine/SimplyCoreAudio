// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SimplyCoreAudio",
    platforms: [.macOS(.v10_12)],
    products: [
        .library(name: "SimplyCoreAudio", targets: ["SimplyCoreAudio"])
    ],
    dependencies: [],
    targets: [
        .target(name: "SimplyCoreAudio", path: "Source"),
        .testTarget(name: "SimplyCoreAudioTests", dependencies: ["SimplyCoreAudio"], path: "Tests")
    ],
    swiftLanguageVersions: [.v4, .v4_2, .v5]
)
