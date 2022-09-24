// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SimplyCoreAudio",
    platforms: [.macOS(.v10_12)],
    
    products: [
        .library(name: "SimplyCoreAudio",
                 targets: ["SimplyCoreAudio"])
    ],
    
    dependencies: [
        .package(url: "https://github.com/apple/swift-atomics.git", from: "0.0.1")
    ],
    
    targets: [
        .target(
            name: "SimplyCoreAudio",
            dependencies: [
                .target(name: "SimplyCoreAudioC"),
                .product(name: "Atomics", package: "swift-atomics")
            ]
        ),
        .target(name: "SimplyCoreAudioC",
                publicHeadersPath: "."
        ),
        .testTarget(
            name: "SimplyCoreAudioTests",
            dependencies: ["SimplyCoreAudio"]
        ),

    ],
    swiftLanguageVersions: [.v4, .v4_2, .v5]
)
