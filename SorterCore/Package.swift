// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SorterCore",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "SorterCore", targets: ["SorterCore"]),
    ],
    targets: [
        .target(name: "SorterCore"),
        .testTarget(
            name: "SorterCoreTests",
            dependencies: ["SorterCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
