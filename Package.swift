// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FFmpegBuild",
    platforms: [
        .iOS(.v16),
        .tvOS(.v16),
        .macOS(.v14),
    ],
    products: [
        // Individual libraries for fine-grained control
        .library(name: "Libavcodec", targets: ["LibavcodecWrapper"]),
        .library(name: "Libavformat", targets: ["LibavformatWrapper"]),
        .library(name: "Libavutil", targets: ["LibavutilWrapper"]),
        .library(name: "Libswresample", targets: ["LibswresampleWrapper"]),
        .library(name: "Libswscale", targets: ["LibswscaleWrapper"]),
        .library(name: "Libdav1d", targets: ["Libdav1dWrapper"]),
        .library(name: "Libavfilter", targets: ["LibavfilterWrapper"]),
        .library(name: "Libzimg", targets: ["LibzimgWrapper"]),
        .library(name: "Libzvbi", targets: ["LibzvbiWrapper"]),
    ],
    targets: [
        // Swift wrapper targets that ensure binary targets are linked.
        // The binary target's framework provides the module interface.
        .target(
            name: "LibavcodecWrapper",
            dependencies: [.target(name: "Libavcodec")],
            path: "Sources/LibavcodecWrapper"
        ),
        .target(
            name: "LibavformatWrapper",
            dependencies: [.target(name: "Libavformat")],
            path: "Sources/LibavformatWrapper"
        ),
        .target(
            name: "LibavutilWrapper",
            dependencies: [.target(name: "Libavutil")],
            path: "Sources/LibavutilWrapper"
        ),
        .target(
            name: "LibswresampleWrapper",
            dependencies: [.target(name: "Libswresample")],
            path: "Sources/LibswresampleWrapper"
        ),
        .target(
            name: "LibswscaleWrapper",
            dependencies: [.target(name: "Libswscale")],
            path: "Sources/LibswscaleWrapper"
        ),
        .target(
            name: "LibavfilterWrapper",
            dependencies: [.target(name: "Libavfilter")],
            path: "Sources/LibavfilterWrapper"
        ),
        .target(
            name: "Libdav1dWrapper",
            dependencies: [.target(name: "Libdav1d")],
            path: "Sources/Libdav1dWrapper"
        ),
        .target(
            name: "LibzimgWrapper",
            dependencies: [.target(name: "Libzimg")],
            path: "Sources/LibzimgWrapper"
        ),
        .target(
            name: "LibzvbiWrapper",
            dependencies: [.target(name: "Libzvbi")],
            path: "Sources/LibzvbiWrapper"
        ),
        // Prebuilt xcframeworks (created by build.sh)
        .binaryTarget(name: "Libavcodec", path: "Sources/Libavcodec.xcframework"),
        .binaryTarget(name: "Libavformat", path: "Sources/Libavformat.xcframework"),
        .binaryTarget(name: "Libavutil", path: "Sources/Libavutil.xcframework"),
        .binaryTarget(name: "Libswresample", path: "Sources/Libswresample.xcframework"),
        .binaryTarget(name: "Libswscale", path: "Sources/Libswscale.xcframework"),
        .binaryTarget(name: "Libdav1d", path: "Sources/Libdav1d.xcframework"),
        .binaryTarget(name: "Libavfilter", path: "Sources/Libavfilter.xcframework"),
        .binaryTarget(name: "Libzimg", path: "Sources/Libzimg.xcframework"),
        .binaryTarget(name: "Libzvbi", path: "Sources/Libzvbi.xcframework"),
        .testTarget(
            name: "FFmpegBuildTests",
            dependencies: ["LibavfilterWrapper", "LibavutilWrapper"],
            path: "Tests/FFmpegBuildTests"
        ),
    ]
)
