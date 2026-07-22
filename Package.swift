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
        .binaryTarget(name: "Libavcodec", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavcodec.xcframework.zip", checksum: "111562496406623dc484d125da9d25cd2fc58e34f2f3a1b6eeb3963048a8062f"),
        .binaryTarget(name: "Libavformat", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavformat.xcframework.zip", checksum: "7e92737d62f81f7735c2d5107437949a9601d6baefe8f721ea54b95a1598c0c3"),
        .binaryTarget(name: "Libavutil", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavutil.xcframework.zip", checksum: "b3bc2219eda65c27454e38920214c53a6bd0b50361aa65701b9d818607399cd9"),
        .binaryTarget(name: "Libswresample", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libswresample.xcframework.zip", checksum: "ddcd84a70b61d6bd8d1aef6610bccb0ce4ad8cdada4539efbd0065dad39c5c3d"),
        .binaryTarget(name: "Libswscale", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libswscale.xcframework.zip", checksum: "32cf4c3b49883d8c4688188eea3f64e384d2f8f897859bd141ae8d87ff0a4d37"),
        .binaryTarget(name: "Libdav1d", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libdav1d.xcframework.zip", checksum: "1d14b002cdfc47e0cd53f76c7b58ba34270d58dd1027363c315a0053b7fb861d"),
        .binaryTarget(name: "Libavfilter", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavfilter.xcframework.zip", checksum: "17f525fe35d11a07e68d370dbf98c67f6e3f3361247602b65fad6a022058ae88"),
        .binaryTarget(name: "Libzimg", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libzimg.xcframework.zip", checksum: "3515d0c4fc309c992dcdf852f01537cb2bb09465a7a2bc866f9accc79f6c0646"),
        .binaryTarget(name: "Libzvbi", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libzvbi.xcframework.zip", checksum: "c09f9d53a630223c53917d5f68dd8da2336686481a617c519b5836ec405dfce9"),
        .testTarget(
            name: "FFmpegBuildTests",
            dependencies: ["LibavfilterWrapper", "LibavutilWrapper"],
            path: "Tests/FFmpegBuildTests"
        ),
    ]
)
