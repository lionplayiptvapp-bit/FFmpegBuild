<h1 align="center">FFmpegBuild</h1>

<p align="center">
  <b>Slim FFmpeg xcframeworks for Apple platforms.</b><br>
  Demux, decode, and a thin HLS-fMP4 mux path for AVPlayer bridging. No network stack, no CLI binaries.
</p>

<p align="center">
  <a href="https://github.com/superuser404notfound/FFmpegBuild/releases/latest"><img src="https://img.shields.io/github/v/release/superuser404notfound/FFmpegBuild?label=release&color=blue"></a>
  <a href="https://swiftpackageindex.com/superuser404notfound/FFmpegBuild"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsuperuser404notfound%2FFFmpegBuild%2Fbadge%3Ftype%3Dswift-versions"></a>
  <a href="https://swiftpackageindex.com/superuser404notfound/FFmpegBuild"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsuperuser404notfound%2FFFmpegBuild%2Fbadge%3Ftype%3Dplatforms"></a>
  <img src="https://img.shields.io/badge/FFmpeg-8.1-brightgreen">
  <img src="https://img.shields.io/badge/dav1d-1.5.1-blue">
  <img src="https://img.shields.io/badge/license-LGPL--3.0-lightgrey">
  <a href="https://ko-fi.com/superuser404"><img src="https://img.shields.io/badge/Ko--fi-Support-FF5E5B?logo=kofi&logoColor=white"></a>
</p>

---

## Why

Full FFmpeg builds for iOS land at 40-70 MB because they bundle a TLS stack, encoders, filters, and a dozen protocols your app will never use. For a player, most of that is dead weight. Apple already ships HTTP/3, `URLSession`, `Network.framework`, VideoToolbox and AVFoundation. So this build strips out everything you don't need and keeps what you do.

**~10 MB per architecture, zero network dependencies, one build script.**

## In

| Library        | What it does                                          |
| -------------- | ----------------------------------------------------- |
| libavformat    | Demux MKV, MP4, WebM, MPEG-TS, MPEG-PS (VOB / DVD), DASH, AVI, OGG, FLV, plus raw elementary streams |
| libavcodec     | Decode video + audio (with VideoToolbox bridge)       |
| libavutil      | Shared primitives                                     |
| libswresample  | Audio resampling / channel remap / format convert     |
| libswscale     | Pixel-format convert (YUV → NV12 / P010) for the SW-decode path |
| libavfilter    | Trimmed filter set: zscale + tonemap + colorspace for HDR → SDR still extraction, bwdif + yadif for deinterlacing on the SW-decode path |
| **dav1d**      | Fast AV1 software decoder (separate xcframework)      |
| **zimg**       | zscale's resampling / colorspace backend (separate xcframework, link-only) |

## Out

Anything the app layer should already handle or doesn't need:

- Network / TLS: FFmpeg reads from an `avio_alloc_context` callback, you wire `URLSession` to it
- Encoders, except FLAC and EAC3 (kept for the audio bridge that re-encodes non-streamable sources like TrueHD / DTS / DTS-HD MA. FLAC for the lossless 7.1 path, EAC3 5.1 for the default soundbar-compat path that surfaces surround via HDMI bitstream tunnel)
- Muxers, except MP4 / MOV / HLS (kept for the HLS-fMP4 producer that wraps streams for AVPlayer)
- libavdevice (libavfilter is included but trimmed to a handful of filters, see In)
- Most filters: libavfilter ships only buffer / buffersink / format / scale / zscale / tonemap / colorspace / bwdif / yadif
- Programs (`ffmpeg`, `ffplay`, `ffprobe`)
- Hardware accel layers other than VideoToolbox
- Text subtitle rendering (do that in SwiftUI)

## Build

```sh
./build.sh          # all platforms
./build.sh tvos     # single platform
./build.sh clean    # wipe everything
```

Needs Xcode 16+ and roughly 10-30 minutes depending on your machine. Both FFmpeg and dav1d sources clone on first run.

Output lands in `Sources/` as xcframeworks, ready to consume via Swift Package Manager.

## Use

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/superuser404notfound/FFmpegBuild", from: "1.0.0")
]

// Target:
.product(name: "FFmpegBuild", package: "FFmpegBuild")
```

Pin `branch: "main"` instead of a version if you want to track the latest rebuilds (that is how [AetherEngine](https://github.com/superuser404notfound/AetherEngine) consumes it).

Then import the modules you need: `Libavformat`, `Libavcodec`, `Libavutil`, `Libswresample`, `Libswscale`, `Libavfilter`, `Libdav1d`. (`Libzimg` is a link-only backend for `zscale`; you don't import it directly.) The umbrella `FFmpegBuild` product links all of them plus the system frameworks (AudioToolbox, CoreMedia, CoreVideo, VideoToolbox) in one shot.

## Decoder support

- **Video (hardware via VideoToolbox)**: H.264, HEVC up to Main10 (HDR10 / DV Profile 8)
- **Video (software)**: AV1 (dav1d), VP9, VP8, MPEG-2, MPEG-4, VC-1
- **Audio**: AAC, AC3, EAC3 (incl. JOC detection for Atmos), FLAC, MP2, MP3, Opus, Vorbis, TrueHD, MLP, DTS, ALAC, PCM (incl. Blu-ray LPCM via `pcm_bluray`)
- **Subtitles**: SRT, ASS, SSA, WebVTT, PGS, DVB, DVD

HDR metadata (BT.2020, SMPTE ST 2084 / PQ, HLG, DV RPU) is preserved end-to-end so the decode pipeline can tag frames correctly.

## Size

Per architecture, release configuration:

| Target                | FFmpeg    | dav1d    | Total     |
| --------------------- | --------- | -------- | --------- |
| iOS / tvOS arm64      | ~9.4 MB   | ~1 MB    | ~10.4 MB  |
| macOS arm64           | ~9.5 MB   | ~1 MB    | ~10.5 MB  |
| macOS x86_64          | ~9.3 MB   | ~2.8 MB  | ~12.1 MB  |

Assembly-optimized paths are enabled where the Apple toolchain permits.

## Built with

This package is vibe-coded, assembled and maintained by [Vincent Herbst](https://github.com/superuser404notfound) in close pair-programming with **Claude** (Anthropic). The commit log is the receipt: nearly every commit carries a `Co-Authored-By: Claude` trailer.

## License

[LGPL-3.0](LICENSE), same as upstream FFmpeg. App Store compatible when linked dynamically.

---

<p align="center"><sub>Used by <a href="https://github.com/superuser404notfound/AetherEngine">AetherEngine</a>.</sub></p>
