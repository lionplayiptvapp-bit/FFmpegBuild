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
        .binaryTarget(name: "Libavcodec", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavcodec.xcframework.zip", checksum: "914b2898c1658a9eb019e2c58924af970ef7bb1ee7580e09cb629794f13003d3"),
        .binaryTarget(name: "Libavformat", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavformat.xcframework.zip", checksum: "5bc856c70f8736f8c105a328bc144923fa22f13b800cad67640346e7e5cc31a2"),
        .binaryTarget(name: "Libavutil", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavutil.xcframework.zip", checksum: "ac68f783c1836f69b9625d57378fedc7b544d4610248b49439744d4d9d4ae7fa"),
        .binaryTarget(name: "Libswresample", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libswresample.xcframework.zip", checksum: "3d225b9420d1f0cf9bbaa62f06cbb99b79089e578ef89fb84f7e3118469f4be8"),
        .binaryTarget(name: "Libswscale", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libswscale.xcframework.zip", checksum: "81469ffba898a181695450bf55eab813368d29b74650f214824137b9c6a4c9f4"),
        .binaryTarget(name: "Libdav1d", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libdav1d.xcframework.zip", checksum: "16205b01818d42b9bb952ca821f011de5d9cc05514a26b64634ea8263e32eb2e"),
        .binaryTarget(name: "Libavfilter", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libavfilter.xcframework.zip", checksum: "143c7e182fa072369a60cf719c5c8c0f4b7e4509ca8ae33b393c39ececef4732"),
        .binaryTarget(name: "Libzimg", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libzimg.xcframework.zip", checksum: "7249f150c224817642c8129e06fd1fee8f6eb41cba2698e91e82dc7755cab140"),
        .binaryTarget(name: "Libzvbi", url: "https://github.com/lionplayiptvapp-bit/FFmpegBuild/releases/download/xcframeworks-v1/Libzvbi.xcframework.zip", checksum: "5df8f6f4605f1233c02de577811f3ccf26a9145cd0113555d551dd1e66d6cc91"),
        .testTarget(
            name: "FFmpegBuildTests",
            dependencies: ["LibavfilterWrapper", "LibavutilWrapper"],
            path: "Tests/FFmpegBuildTests"
        ),
    ]
)
