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
        .library(name: "FFmpeg", targets: ["FFmpegWrapper"]),
    ],
    targets: [
        // Single wrapper target that imports the unified FFmpeg module
        // and links all individual library binaries.
        .target(
            name: "FFmpegWrapper",
            dependencies: [
                .target(name: "FFmpeg"),
                .target(name: "Libavutil"),
                .target(name: "Libavcodec"),
                .target(name: "Libavformat"),
                .target(name: "Libswresample"),
                .target(name: "Libswscale"),
                .target(name: "Libavfilter"),
                .target(name: "Libdav1d"),
                .target(name: "Libzimg"),
                .target(name: "Libzvbi"),
            ],
            path: "Sources/FFmpegWrapper"
        ),
        // Unified FFmpeg framework with all headers and a single module map
        .binaryTarget(name: "FFmpeg", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/FFmpeg.xcframework.zip", checksum: "7b92ef93192b4383080f920227bb6cb7719162b7ac82e16e6fd243faa2003563"),
        // Individual library binaries for linking (no module maps)
        .binaryTarget(name: "Libavcodec", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavcodec.xcframework.zip", checksum: "3fa260c08f49d75073d775030d2b91b0560e522d99a7b1c573a5a78a642cb8db"),
        .binaryTarget(name: "Libavformat", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavformat.xcframework.zip", checksum: "1835d3c289752219efe937dd46cbdaf1f3e03263374e7b72c14761955894c954"),
        .binaryTarget(name: "Libavutil", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavutil.xcframework.zip", checksum: "13d529ba8e82a68d235e03a45d0accf731c2bf54c3623700c39c6f12cd6e26de"),
        .binaryTarget(name: "Libswresample", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libswresample.xcframework.zip", checksum: "0753978990c3cf6490820bb742d960a10ebf024e676ad6296407d691fcdcd682"),
        .binaryTarget(name: "Libswscale", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libswscale.xcframework.zip", checksum: "65020dfb65670dc10e7b25aef2a5b7ffe5fdf54221edc4efb506cc48ac67132e"),
        .binaryTarget(name: "Libdav1d", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libdav1d.xcframework.zip", checksum: "2ff4922a57e116dfe62caa247bf1b386713829ef77b3f26e000a32f13ced2126"),
        .binaryTarget(name: "Libavfilter", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavfilter.xcframework.zip", checksum: "d00fe16e10b4f6cc18765f941d498816d17bcf8edcd944edf80265b9e1edcbe2"),
        .binaryTarget(name: "Libzimg", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libzimg.xcframework.zip", checksum: "b2af41b4a7ad0b5c7c875fa84829a2e9f8399166c257af88df131c17dc0fb08a"),
        .binaryTarget(name: "Libzvbi", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libzvbi.xcframework.zip", checksum: "142c6268d0697fabe93bb38b8ccea9b9c9b8f19f71b6dcf26978e7924d3f3633"),
        .testTarget(
            name: "FFmpegBuildTests",
            dependencies: ["FFmpegWrapper"],
            path: "Tests/FFmpegBuildTests"
        ),
    ]
)
