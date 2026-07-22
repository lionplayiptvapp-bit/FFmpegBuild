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
        .library(
            name: "FFmpegBuild",
            targets: ["FFmpegBuild"]
        ),
        // Individual libraries for consumers that want fine-grained control
        .library(name: "Libavcodec", targets: ["Libavcodec"]),
        .library(name: "Libavformat", targets: ["Libavformat"]),
        .library(name: "Libavutil", targets: ["Libavutil"]),
        .library(name: "Libswresample", targets: ["Libswresample"]),
        .library(name: "Libswscale", targets: ["Libswscale"]),
        .library(name: "Libdav1d", targets: ["Libdav1d"]),
        .library(name: "Libavfilter", targets: ["Libavfilter"]),
        .library(name: "Libzimg", targets: ["Libzimg"]),
        .library(name: "Libzvbi", targets: ["Libzvbi"]),
    ],
    targets: [
        // Umbrella target that links all FFmpeg libraries + dav1d + system frameworks
        .target(
            name: "FFmpegBuild",
            dependencies: [
                "Libavcodec",
                "Libavformat",
                "Libavutil",
                "Libswresample",
                "Libswscale",
                "Libavfilter",
                "Libdav1d",
                "Libzimg",
                "Libzvbi",
            ],
            path: "Sources/FFmpegBuild",
            linkerSettings: [
                .linkedFramework("AudioToolbox"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("VideoToolbox"),
                .linkedLibrary("z"),
                .linkedLibrary("bz2"),
                .linkedLibrary("iconv"),
                .linkedLibrary("c++"),
            ]
        ),
        // C wrapper targets that expose binary framework headers as Swift modules
        .target(
            name: "Libavcodec",
            dependencies: [.target(name: "LibavcodecBT")],
            path: "Sources/LibavcodecWrapper",
            publicHeadersPath: "."
        ),
        .target(
            name: "Libavformat",
            dependencies: [.target(name: "LibavformatBT")],
            path: "Sources/LibavformatWrapper",
            publicHeadersPath: "."
        ),
        .target(
            name: "Libavutil",
            dependencies: [.target(name: "LibavutilBT")],
            path: "Sources/LibavutilWrapper",
            publicHeadersPath: "."
        ),
        .target(
            name: "Libswresample",
            dependencies: [.target(name: "LibswresampleBT")],
            path: "Sources/LibswresampleWrapper",
            publicHeadersPath: "."
        ),
        .target(
            name: "Libswscale",
            dependencies: [.target(name: "LibswscaleBT")],
            path: "Sources/LibswscaleWrapper",
            publicHeadersPath: "."
        ),
        .target(
            name: "Libavfilter",
            dependencies: [.target(name: "LibavfilterBT")],
            path: "Sources/LibavfilterWrapper",
            publicHeadersPath: "."
        ),
        // Prebuilt xcframeworks (created by build.sh)
        .binaryTarget(name: "LibavcodecBT", path: "Sources/Libavcodec.xcframework"),
        .binaryTarget(name: "LibavformatBT", path: "Sources/Libavformat.xcframework"),
        .binaryTarget(name: "LibavutilBT", path: "Sources/Libavutil.xcframework"),
        .binaryTarget(name: "LibswresampleBT", path: "Sources/Libswresample.xcframework"),
        .binaryTarget(name: "LibswscaleBT", path: "Sources/Libswscale.xcframework"),
        .binaryTarget(name: "Libdav1d", path: "Sources/Libdav1d.xcframework"),
        .binaryTarget(name: "LibavfilterBT", path: "Sources/Libavfilter.xcframework"),
        .binaryTarget(name: "Libzimg", path: "Sources/Libzimg.xcframework"),
        .binaryTarget(name: "Libzvbi", path: "Sources/Libzvbi.xcframework"),
        .testTarget(
            name: "FFmpegBuildTests",
            dependencies: ["FFmpegBuild", "Libavfilter", "Libavutil"],
            path: "Tests/FFmpegBuildTests"
        ),
    ]
)
