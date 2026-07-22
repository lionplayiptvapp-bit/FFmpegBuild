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
            name: "LibavutilWrapper",
            dependencies: [.target(name: "Libavutil")],
            path: "Sources/LibavutilWrapper"
        ),
        .target(
            name: "LibavcodecWrapper",
            dependencies: [.target(name: "Libavcodec"), .target(name: "LibavutilWrapper")],
            path: "Sources/LibavcodecWrapper"
        ),
        .target(
            name: "LibavformatWrapper",
            dependencies: [.target(name: "Libavformat"), .target(name: "LibavcodecWrapper"), .target(name: "LibavutilWrapper")],
            path: "Sources/LibavformatWrapper"
        ),
        .target(
            name: "LibswresampleWrapper",
            dependencies: [.target(name: "Libswresample"), .target(name: "LibavutilWrapper")],
            path: "Sources/LibswresampleWrapper"
        ),
        .target(
            name: "LibswscaleWrapper",
            dependencies: [.target(name: "Libswscale"), .target(name: "LibavutilWrapper")],
            path: "Sources/LibswscaleWrapper"
        ),
        .target(
            name: "LibavfilterWrapper",
            dependencies: [.target(name: "Libavfilter"), .target(name: "LibavformatWrapper"), .target(name: "LibavcodecWrapper"), .target(name: "LibswscaleWrapper"), .target(name: "LibswresampleWrapper"), .target(name: "LibavutilWrapper")],
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
        // Prebuilt xcframeworks hosted on GitHub releases
        .binaryTarget(name: "Libavcodec", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavcodec.xcframework.zip", checksum: "b1eebd022f00b8a704e6e01e4062744b59850314119b9b60944717cf3f943ca0"),
        .binaryTarget(name: "Libavformat", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavformat.xcframework.zip", checksum: "293dcdb08fd94af15946019886a710f1aacb85533d97f06338f19952b5425bde"),
        .binaryTarget(name: "Libavutil", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavutil.xcframework.zip", checksum: "9d1e9365baf2b109a45f8542ffa32145b746dd1307bcf25c2bc2d2b2eefdf57a"),
        .binaryTarget(name: "Libswresample", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libswresample.xcframework.zip", checksum: "a380e86d227814802f51e0dbcb99223389630c23260cd067d8760a71cbe76d79"),
        .binaryTarget(name: "Libswscale", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libswscale.xcframework.zip", checksum: "abf52a4e1363fb573f46d064f487da708f04fb98672abf07328935d7bcdfe18a"),
        .binaryTarget(name: "Libdav1d", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libdav1d.xcframework.zip", checksum: "1d14b002cdfc47e0cd53f76c7b58ba34270d58dd1027363c315a0053b7fb861d"),
        .binaryTarget(name: "Libavfilter", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavfilter.xcframework.zip", checksum: "cb71b89abf505899beb32fbb53fff7b637930ce1d2843d9cea396cd3bb6f9aec"),
        .binaryTarget(name: "Libzimg", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libzimg.xcframework.zip", checksum: "3515d0c4fc309c992dcdf852f01537cb2bb09465a7a2bc866f9accc79f6c0646"),
        .binaryTarget(name: "Libzvbi", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libzvbi.xcframework.zip", checksum: "c09f9d53a630223c53917d5f68dd8da2336686481a617c519b5836ec405dfce9"),
        .testTarget(
            name: "FFmpegBuildTests",
            dependencies: ["LibavfilterWrapper", "LibavutilWrapper"],
            path: "Tests/FFmpegBuildTests"
        ),
    ]
)
