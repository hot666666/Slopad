// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DownstreamAppKitHost",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "DownstreamAppKitHost",
            dependencies: [
                .product(name: "SlopadAppKitTextKit", package: "Slopad"),
                .product(name: "SlopadAppKitUI", package: "Slopad"),
                .product(name: "SlopadEngine", package: "Slopad"),
            ]
        )
    ]
)
