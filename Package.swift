// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Slopad",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SlopadEngine",
            targets: ["SlopadEngine"]
        ),
        .library(
            name: "SlopadTextKit",
            targets: ["SlopadTextKit"]
        ),
        .library(
            name: "SlopadAppKitUI",
            targets: ["SlopadAppKitUI"]
        ),
        .executable(
            name: "SlopadDebugApp",
            targets: ["SlopadDebugApp"]
        ),
        .executable(
            name: "SlopadUIBenchmarkApp",
            targets: ["SlopadUIBenchmarkApp"]
        )
    ],
    targets: [
        .target(
            name: "SlopadCoreModel"
        ),
        .target(
            name: "SlopadDataStructure"
        ),
        .target(
            name: "SlopadEditorModel",
            dependencies: ["SlopadCoreModel"]
        ),
        .target(
            name: "SlopadBlockLayout",
            dependencies: [
                "SlopadCoreModel",
                "SlopadDataStructure",
            ]
        ),
        .target(
            name: "SlopadEngine",
            dependencies: [
                "SlopadCoreModel",
                "SlopadEditorModel",
                "SlopadBlockLayout",
            ]
        ),
        .target(
            name: "SlopadTextKit",
            dependencies: [
                "SlopadCoreModel",
                "SlopadEngine",
            ]
        ),
        .target(
            name: "SlopadAppKitUI",
            dependencies: [
                "SlopadEngine",
                "SlopadTextKit",
            ]
        ),
        .executableTarget(
            name: "SlopadHeightBenchmark",
            dependencies: [
                "SlopadCoreModel",
                "SlopadBlockLayout",
            ],
            path: "Benchmarks/SlopadHeightBenchmark"
        ),
        .executableTarget(
            name: "SlopadSessionBenchmark",
            dependencies: ["SlopadEngine"],
            path: "Benchmarks/SlopadSessionBenchmark"
        ),
        .executableTarget(
            name: "SlopadDebugApp",
            dependencies: [
                "SlopadEngine",
                "SlopadTextKit",
                "SlopadAppKitUI",
            ],
            path: "Debug/SlopadDebugApp"
        ),
        .executableTarget(
            name: "SlopadUIBenchmarkApp",
            dependencies: [
                "SlopadEngine",
                "SlopadTextKit",
                "SlopadAppKitUI",
            ],
            path: "Benchmarks/SlopadUIBenchmarkApp"
        ),
        .testTarget(
            name: "SlopadEngineTests",
            dependencies: [
                "SlopadCoreModel",
                "SlopadDataStructure",
                "SlopadEditorModel",
                "SlopadBlockLayout",
                "SlopadEngine",
            ]
        ),
        .testTarget(
            name: "SlopadTextKitTests",
            dependencies: [
                "SlopadCoreModel",
                "SlopadEngine",
                "SlopadTextKit"
            ]
        )
    ]
)
