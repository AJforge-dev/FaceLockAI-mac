// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FaceVault",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "FaceVault",
            targets: ["FaceVault"]
        ),
        .executable(
            name: "FaceVaultTests",
            targets: ["FaceVaultTests"]
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
                .linkedFramework("LocalAuthentication"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .executableTarget(
            name: "FaceVault",
            dependencies: ["FaceLockCore"],
            path: "Sources/FaceLockAI"
        ),
        .executableTarget(
            name: "FaceVaultTests",
            dependencies: ["FaceLockCore"],
            path: "Tests/FaceLockAITests"
        )
    ]
)
