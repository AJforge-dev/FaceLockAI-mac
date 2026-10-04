// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FaceLockAI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "FaceLockAI",
            targets: ["FaceLockAI"]
        ),
        .executable(
            name: "FaceLockAITests",
            targets: ["FaceLockAITests"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FaceLockCore",
            dependencies: [],
            path: "Sources/FaceLockCore",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("Vision"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("CoreImage"),
                .linkedFramework("Security"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .executableTarget(
            name: "FaceLockAI",
            dependencies: ["FaceLockCore"],
            path: "Sources/FaceLockAI"
        ),
        .executableTarget(
            name: "FaceLockAITests",
            dependencies: ["FaceLockCore"],
            path: "Tests/FaceLockAITests"
        )
    ]
)
