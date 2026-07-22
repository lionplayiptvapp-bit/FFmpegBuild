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
        // Prebuilt xcframeworks hosted on GitHub releases
        .binaryTarget(name: "Libavcodec", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavcodec.xcframework.zip", checksum: "50527d60694347e771357cc643d6ba2b652332a2023697c39c5ff9701093dfff"),
        .binaryTarget(name: "Libavformat", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavformat.xcframework.zip", checksum: "65e26b1c2be90aab3a126e1979a7d65c3cd8a56760aa90b445e0f8bf303c5d4f"),
        .binaryTarget(name: "Libavutil", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavutil.xcframework.zip", checksum: "1897c17c253bf11321c817a48fdb81dc3df3196aaba4872984209e225b1555c9"),
        .binaryTarget(name: "Libswresample", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libswresample.xcframework.zip", checksum: "69b1d4ca7ec55f2e91d325884934330f1ac8c126a50eb63a308062892b6c8eb2"),
        .binaryTarget(name: "Libswscale", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libswscale.xcframework.zip", checksum: "fe03ec5f7aeea04121f90f8660cf8f317efa8676d97fac9375b2c141849d6002"),
        .binaryTarget(name: "Libdav1d", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libdav1d.xcframework.zip", checksum: "6e591765a9f1302238666028a78b6cbcba23186816e965ace7cf7e2fabdc98a3"),
        .binaryTarget(name: "Libavfilter", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavfilter.xcframework.zip", checksum: "4478d7fbb6ad9b36cbeb36098b52e807f0aa7b89f2f5c2ae306aa2b26ed999be"),
        .binaryTarget(name: "Libzimg", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libzimg.xcframework.zip", checksum: "20fd577bbacc3ddc65bc459215ffc36ce7cf1c3c54df209849541b0ade9261c8"),
        .binaryTarget(name: "Libzvbi", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libzvbi.xcframework.zip", checksum: "722f71e797290886730a9ffbe1882465ba735ec53fc5a1345f5ee262bad1e8fe"),
        .testTarget(
            name: "FFmpegBuildTests",
            dependencies: ["LibavfilterWrapper", "LibavutilWrapper"],
            path: "Tests/FFmpegBuildTests"
        ),
    ]
)
