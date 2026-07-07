#!/bin/zsh
#
# FFmpegBuild: Minimal FFmpeg cross-compilation for Apple platforms.
# Includes dav1d (fast AV1 software decoder).
#
# Usage:
#   ./build.sh          # Build all platforms
#   ./build.sh clean    # Remove all build artifacts
#
set -eo pipefail  # pipefail so `... | tail -N` doesn't swallow configure/make errors

FFMPEG_VERSION="n8.1.2"
FFMPEG_REPO="https://github.com/FFmpeg/FFmpeg.git"
DAV1D_VERSION="1.5.1"
DAV1D_REPO="https://code.videolan.org/videolan/dav1d.git"
ZIMG_VERSION="release-3.0.5"
ZIMG_REPO="https://github.com/sekrit-twc/zimg.git"
ZVBI_VERSION="v0.2.44"
ZVBI_REPO="https://github.com/zapping-vbi/zvbi.git"
SCRIPT_DIR="${0:a:h}"
BUILD_DIR="${SCRIPT_DIR}/build"
OUTPUT_DIR="${SCRIPT_DIR}/Sources"
FFMPEG_SRC="${BUILD_DIR}/ffmpeg-src"
DAV1D_SRC="${BUILD_DIR}/dav1d-src"
ZIMG_SRC="${BUILD_DIR}/zimg-src"
ZVBI_SRC="${BUILD_DIR}/zvbi-src"

# ─────────────────────────────────────────────────────────

fetch_ffmpeg() {
    if [[ -d "${FFMPEG_SRC}" ]]; then
        echo "→ FFmpeg source already exists, skipping clone"
        return
    fi
    echo "→ Cloning FFmpeg ${FFMPEG_VERSION}..."
    git clone --depth 1 --branch "${FFMPEG_VERSION}" "${FFMPEG_REPO}" "${FFMPEG_SRC}"
}

fetch_dav1d() {
    if [[ -d "${DAV1D_SRC}" ]]; then
        echo "→ dav1d source already exists, skipping clone"
        return
    fi
    echo "→ Cloning dav1d ${DAV1D_VERSION}..."
    git clone --depth 1 --branch "${DAV1D_VERSION}" "${DAV1D_REPO}" "${DAV1D_SRC}"
}

fetch_zimg() {
    if [[ -d "${ZIMG_SRC}" ]]; then
        echo "→ zimg source already exists, skipping clone"
        return
    fi
    echo "→ Cloning zimg ${ZIMG_VERSION}..."
    git clone --depth 1 --branch "${ZIMG_VERSION}" --recurse-submodules "${ZIMG_REPO}" "${ZIMG_SRC}"
    # zimg ships an autotools build; generate the configure script once.
    # macOS Homebrew installs GNU libtool as glibtoolize; this gnubin dir
    # exposes it (and friends) under their normal names so autogen.sh's
    # libtoolize call resolves.
    ( cd "${ZIMG_SRC}" && PATH="/opt/homebrew/opt/libtool/libexec/gnubin:${PATH}" ./autogen.sh )
}

fetch_zvbi() {
    if [[ -d "${ZVBI_SRC}" ]]; then
        echo "→ zvbi source already exists, skipping clone"
        return
    fi
    echo "→ Cloning zvbi ${ZVBI_VERSION}..."
    git clone --depth 1 --branch "${ZVBI_VERSION}" "${ZVBI_REPO}" "${ZVBI_SRC}"
    # libzvbi ships autotools sources without a generated configure; bootstrap once.
    # gettext's autopoint and Homebrew's GNU libtool (as glibtoolize) must be on PATH.
    ( cd "${ZVBI_SRC}" && PATH="/opt/homebrew/opt/libtool/libexec/gnubin:/opt/homebrew/opt/gettext/bin:${PATH}" NOCONFIGURE=1 ./autogen.sh )
}

# ─────────────────────────────────────────────────────────
# dav1d cross-compilation (Meson + Ninja)
# ─────────────────────────────────────────────────────────

build_dav1d_one() {
    local KEY="$1" SDK="$2" ARCH="$3" TARGET="$4" MIN_VER="$5"

    echo ""
    echo "━━━ Building dav1d: ${KEY} (${ARCH} for ${SDK}) ━━━"

    local SDK_PATH=$(xcrun --sdk "${SDK}" --show-sdk-path)
    local INSTALL_DIR="${BUILD_DIR}/dav1d-thin/${KEY}"
    local WORK_DIR="${BUILD_DIR}/dav1d-work/${KEY}"
    rm -rf "${WORK_DIR}"
    mkdir -p "${WORK_DIR}" "${INSTALL_DIR}"

    # Determine CPU family and system for Meson cross file
    local CPU_FAMILY="aarch64"
    local CPU="aarch64"
    [[ "${ARCH}" == "x86_64" ]] && CPU_FAMILY="x86_64" && CPU="x86_64"

    local SYSTEM="darwin"

    # Create Meson cross file
    cat > "${WORK_DIR}/cross.txt" << CROSSEOF
[binaries]
c = '/usr/bin/clang'
ar = '/usr/bin/ar'
strip = '/usr/bin/strip'

[built-in options]
c_args = ['-arch', '${ARCH}', '-isysroot', '${SDK_PATH}', '-target', '${TARGET}', '-fno-common']
c_link_args = ['-arch', '${ARCH}', '-isysroot', '${SDK_PATH}', '-target', '${TARGET}']

[host_machine]
system = '${SYSTEM}'
cpu_family = '${CPU_FAMILY}'
cpu = '${CPU}'
endian = 'little'
CROSSEOF

    cd "${WORK_DIR}"

    meson setup \
        --cross-file "${WORK_DIR}/cross.txt" \
        --prefix="${INSTALL_DIR}" \
        --default-library=static \
        --buildtype=release \
        -Denable_tools=false \
        -Denable_examples=false \
        -Denable_tests=false \
        "${DAV1D_SRC}" \
        2>&1 | tail -5

    ninja -j$(sysctl -n hw.ncpu) 2>&1 | tail -3
    ninja install 2>&1 | tail -3

    echo "✓ dav1d ${KEY} → ${INSTALL_DIR}"
}

# ─────────────────────────────────────────────────────────
# zimg cross-compilation (autotools)
# ─────────────────────────────────────────────────────────

build_zimg_one() {
    local KEY="$1" SDK="$2" ARCH="$3" TARGET="$4" MIN_VER="$5"

    echo ""
    echo "━━━ Building zimg: ${KEY} (${ARCH} for ${SDK}) ━━━"

    local SDK_PATH=$(xcrun --sdk "${SDK}" --show-sdk-path)
    local INSTALL_DIR="${BUILD_DIR}/zimg-thin/${KEY}"
    local WORK_DIR="${BUILD_DIR}/zimg-work/${KEY}"
    rm -rf "${WORK_DIR}"
    mkdir -p "${WORK_DIR}" "${INSTALL_DIR}"

    local HOST_TRIPLE="aarch64-apple-darwin"
    [[ "${ARCH}" == "x86_64" ]] && HOST_TRIPLE="x86_64-apple-darwin"

    local FLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -target ${TARGET} -fno-common"

    cd "${WORK_DIR}"
    CC="clang ${FLAGS}" \
    CXX="clang++ ${FLAGS}" \
    "${ZIMG_SRC}/configure" \
        --host="${HOST_TRIPLE}" \
        --prefix="${INSTALL_DIR}" \
        --enable-static \
        --disable-shared \
        2>&1 | tail -5

    make -j$(sysctl -n hw.ncpu) 2>&1 | tail -3
    make install 2>&1 | tail -3

    echo "✓ zimg ${KEY} → ${INSTALL_DIR}"
}

# ─────────────────────────────────────────────────────────
# libzvbi cross-compilation (autotools) - DVB teletext subtitle decoding
# ─────────────────────────────────────────────────────────

build_zvbi_one() {
    local KEY="$1" SDK="$2" ARCH="$3" TARGET="$4" MIN_VER="$5"

    echo ""
    echo "━━━ Building zvbi: ${KEY} (${ARCH} for ${SDK}) ━━━"

    local SDK_PATH=$(xcrun --sdk "${SDK}" --show-sdk-path)
    local INSTALL_DIR="${BUILD_DIR}/zvbi-thin/${KEY}"
    local WORK_DIR="${BUILD_DIR}/zvbi-work/${KEY}"
    rm -rf "${WORK_DIR}" "${INSTALL_DIR}"
    mkdir -p "${WORK_DIR}" "${INSTALL_DIR}"

    local HOST_TRIPLE="aarch64-apple-darwin"
    [[ "${ARCH}" == "x86_64" ]] && HOST_TRIPLE="x86_64-apple-darwin"

    # -fgnu89-inline: libzvbi's misc.h inline helpers need GNU89 extern-inline emission under clang.
    local FLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -target ${TARGET} -fno-common -fgnu89-inline"

    cd "${WORK_DIR}"
    # ac_cv_func_(malloc|realloc)_0_nonnull=yes: AC_FUNC_MALLOC/REALLOC run a runtime probe that cannot
    # execute when cross-compiling, so autoconf assumes a broken allocator and substitutes gnulib's
    # rpl_malloc/rpl_realloc, which libzvbi never provides (undefined symbols at the FFmpeg link).
    CC="clang ${FLAGS}" \
    CFLAGS="${FLAGS}" \
    ac_cv_func_malloc_0_nonnull=yes \
    ac_cv_func_realloc_0_nonnull=yes \
    "${ZVBI_SRC}/configure" \
        --host="${HOST_TRIPLE}" \
        --prefix="${INSTALL_DIR}" \
        --enable-static \
        --disable-shared \
        --disable-nls \
        --disable-tests \
        --disable-examples \
        --without-doxygen \
        2>&1 | tail -5

    # Only src/ holds the decoder library; test/ and examples/ are disabled above.
    make -C src -j$(sysctl -n hw.ncpu) 2>&1 | tail -3
    make -C src install 2>&1 | tail -3
    make install-pkgconfigDATA 2>&1 | tail -2

    echo "✓ zvbi ${KEY} → ${INSTALL_DIR}"
}

# ─────────────────────────────────────────────────────────
# FFmpeg
# ─────────────────────────────────────────────────────────

COMMON_FLAGS=(
    --enable-static --disable-shared --enable-pic
    --enable-optimizations --enable-stripping --disable-debug
    --disable-autodetect --disable-doc --disable-programs
    --disable-devices --disable-outdevs --disable-indevs
    --disable-avdevice --enable-avfilter
    --enable-swscale --disable-encoders --disable-muxers
    --disable-bsfs --disable-network --disable-protocols
    --disable-d3d11va --disable-dxva2 --disable-vaapi --disable-vdpau
    --disable-gray --disable-iconv --disable-bzlib
    --disable-linux-perf --disable-symver --disable-swscale-alpha
    --enable-avcodec --enable-avformat --enable-avutil --enable-swresample
    --enable-libzimg
    --enable-libzvbi
    --disable-filters
    --enable-filter=buffer --enable-filter=buffersink
    --enable-filter=format --enable-filter=scale
    --enable-filter=zscale --enable-filter=tonemap
    --enable-filter=colorspace
    # Deinterlacers for AetherEngine's software-decode path. Interlaced
    # H.264 routes to native AVPlayer (which deinterlaces itself), but
    # interlaced MPEG-2 / VC-1 / MPEG-4 (DVD rips, SD broadcast channels)
    # decode through libavcodec and would render with combing otherwise.
    # bwdif is the primary (better quality), yadif the fallback.
    --enable-filter=bwdif --enable-filter=yadif
    --enable-videotoolbox --enable-audiotoolbox
    --enable-libdav1d
    --enable-protocol=file --enable-protocol=pipe --enable-protocol=data
    --disable-demuxers
    --enable-demuxer=hls --enable-demuxer=dash --enable-demuxer=matroska
    --enable-demuxer=mov --enable-demuxer=mpegts --enable-demuxer=mpegps
    --enable-demuxer=avi --enable-demuxer=flv --enable-demuxer=h264
    --enable-demuxer=hevc --enable-demuxer=aac --enable-demuxer=ac3
    --enable-demuxer=eac3 --enable-demuxer=flac --enable-demuxer=ogg
    --enable-demuxer=wav --enable-demuxer=mp3 --enable-demuxer=srt
    --enable-demuxer=ass --enable-demuxer=concat --enable-demuxer=data
    # Raw MPEG-1/2 and MPEG-4 video elementary-stream demuxers. The mpegps
    # (MPEG Program Stream / DVD VOB) demuxer carries no codec signaling, so
    # it tags a 0x1E0-0x1EF video stream as request_probe and confirms the
    # codec via these raw demuxers' probe functions. Without them MPEG-2
    # video in a Program Stream is never confirmed (the lenient mp3 demuxer
    # probe wins instead) and no video stream is exposed: DVD-Video ISO
    # playback shows audio only. The h264/hevc raw demuxers above already
    # cover H.264/HEVC-in-PS; these add MPEG-2 (DVD) and MPEG-4 Part 2.
    --enable-demuxer=mpegvideo --enable-demuxer=m4v
    --disable-decoders
    --enable-decoder=h264 --enable-decoder=hevc --enable-decoder=vp8
    --enable-decoder=vp9 --enable-decoder=av1 --enable-decoder=libdav1d
    --enable-decoder=mpeg2video --enable-decoder=mpeg4 --enable-decoder=vc1
    --enable-decoder=aac --enable-decoder=aac_latm --enable-decoder=ac3
    --enable-decoder=eac3 --enable-decoder=flac --enable-decoder=mp3
    --enable-decoder=mp3float --enable-decoder=opus --enable-decoder=vorbis
    --enable-decoder=truehd --enable-decoder=mlp --enable-decoder=dca --enable-decoder=alac
    --enable-decoder=pcm_s16le --enable-decoder=pcm_s24le --enable-decoder=pcm_f32le
    # Blu-ray LPCM (PCM_BLURAY): M2TS audio tracks that ship raw LPCM. Not
    # legal in fMP4, so AetherEngine's AudioBridge decodes to PCM and
    # re-encodes; without the decoder those tracks are silent. Prep for
    # Blu-ray ISO support (Phase 2); harmless for everything else.
    --enable-decoder=pcm_bluray
    # MP2 (MPEG-1 Layer II) decoder for DVD-remux audio tracks that
    # still carry MP2. Not legal in fMP4 so AetherEngine's AudioBridge
    # decodes to PCM and re-encodes as FLAC. ~5 KB binary cost.
    --enable-decoder=mp2
    --enable-decoder=ass --enable-decoder=srt --enable-decoder=subrip
    --enable-decoder=movtext --enable-decoder=dvdsub --enable-decoder=dvbsub
    --enable-decoder=pgssub --enable-decoder=webvtt
    --enable-decoder=libzvbi_teletext
    --disable-parsers
    --enable-parser=aac --enable-parser=aac_latm --enable-parser=ac3
    --enable-parser=flac --enable-parser=h264 --enable-parser=hevc
    --enable-parser=mpegaudio --enable-parser=mpeg4video
    --enable-parser=mpegvideo --enable-parser=opus --enable-parser=vorbis
    --enable-parser=vp8 --enable-parser=vp9 --enable-parser=av1
    # dca parser coalesces a DTS core frame and the following DTS-HD extension
    # substream (EXSS) into one packet. Without it, the MPEG-TS demuxer hands the
    # decoder the core (0x7FFE8001) and the EXSS (0x64582025) as SEPARATE packets,
    # so a DTS-HD MA EXSS arrives with no core and the decoder rejects every frame
    # with "Residual encoded channels are present without core" (silent audio on
    # Blu-ray M2TS; AetherEngine #64). Matroska is unaffected (its blocks are
    # already whole frames), which is why only the .m2ts path was silent.
    --enable-parser=dca
    # Same framing-completeness class as dca, for the other enabled decoders whose
    # frames the MPEG-TS / MPEG-PS demuxer can only deliver correctly with a parser:
    #   mlp  -> TrueHD / MLP (common on Blu-ray M2TS; the AudioBridge decodes it).
    #           Without it, TrueHD access units mis-frame exactly like DTS-HD MA did.
    #   vc1  -> VC-1 video (Blu-ray, WMV); the software decode path needs framed BDUs.
    #   dvbsub / dvdsub -> DVB (live TS) and DVD (Program Stream / VOB) bitmap subtitles.
    #           Defensive: matches a stock FFmpeg build so live-TV / DVD subtitle
    #           framing is correct rather than relying on PES-aligned delivery.
    --enable-parser=mlp --enable-parser=vc1
    --enable-parser=dvbsub --enable-parser=dvdsub
    --enable-bsf=aac_adtstoasc --enable-bsf=h264_mp4toannexb
    --enable-bsf=hevc_mp4toannexb --enable-bsf=extract_extradata
    # dca_core extracts the mandatory DTS core substream from a DTS-HD
    # (MA / HRA) packet at the bitstream level. AetherEngine's AudioBridge
    # runs DTS through it before decode so the lossless XLL extension (which
    # residual-codes channels and can fail to reconstruct standalone) is
    # dropped up front; the bridge re-encodes lossy anyway. Yields clean
    # full-rate 5.1/7.1 core PCM on every frame (AetherEngine #64).
    --enable-bsf=dca_core
    # MP4 / mov muxers underlie the per-fragment fmp4 segment output;
    # the hls muxer drives the segmentation + per-segment styp emission
    # + playlist for AetherEngine's HLSVideoEngine. We override
    # `s->io_open` / `s->io_close2` so segment writes land in Swift
    # memory rather than on disk, but the muxer's logic itself is
    # libavformat's hlsenc.c verbatim, byte-identical to
    # `ffmpeg -f hls -hls_segment_type fmp4`.
    --enable-muxer=mp4 --enable-muxer=mov --enable-muxer=hls
    # FLAC encoder kept for stereo / lossless paths and CLI tools.
    --enable-encoder=flac
    # EAC3 encoder for the multichannel bridge. AVPlayer decodes FLAC
    # to LPCM and routes that through the active HDMI port's channel
    # count — most consumer soundbars (Sonos Arc and equivalents)
    # accept multichannel only via bitstream codecs (EAC3, AC3, DD+,
    # Atmos), not LPCM, so a 7.1 FLAC track gets downmixed to stereo
    # at the route. EAC3 5.1 bridges that gap: AVPlayer hands the
    # encoded bitstream to HDMI, the sink decodes its own 5.1 mix,
    # surround works on every device that decodes EAC3 (which is
    # essentially every modern AVR + soundbar). Trade-off: lossy
    # (~384 kbps for 5.1) versus the FLAC bridge's lossless, but
    # tvOS doesn't expose LPCM-side audio passthrough that the
    # lossless was actually delivering on most setups anyway.
    --enable-encoder=eac3
)

build_one() {
    local KEY="$1" SDK="$2" ARCH="$3" TARGET="$4" MIN_VER="$5"

    echo ""
    echo "━━━ Building FFmpeg: ${KEY} (${ARCH} for ${SDK}) ━━━"

    local SDK_PATH=$(xcrun --sdk "${SDK}" --show-sdk-path)
    local INSTALL_DIR="${BUILD_DIR}/thin/${KEY}"
    local DAV1D_DIR="${BUILD_DIR}/dav1d-thin/${KEY}"
    local ZIMG_DIR="${BUILD_DIR}/zimg-thin/${KEY}"
    local ZVBI_DIR="${BUILD_DIR}/zvbi-thin/${KEY}"
    mkdir -p "${INSTALL_DIR}"

    local CFLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -target ${TARGET} -fno-common -DHAVE_FORK=0"
    local LDFLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -target ${TARGET}"

    # Add dav1d include/lib paths
    CFLAGS="${CFLAGS} -I${DAV1D_DIR}/include"
    LDFLAGS="${LDFLAGS} -L${DAV1D_DIR}/lib"

    # Add zimg include/lib paths (zimg is C++, so the FFmpeg link needs -lc++)
    CFLAGS="${CFLAGS} -I${ZIMG_DIR}/include"
    LDFLAGS="${LDFLAGS} -L${ZIMG_DIR}/lib -lc++"

    # Add libzvbi include/lib paths (DVB teletext decoding; -liconv for teletext charset conversion)
    CFLAGS="${CFLAGS} -I${ZVBI_DIR}/include"
    LDFLAGS="${LDFLAGS} -L${ZVBI_DIR}/lib -liconv"

    local ASM_FLAGS=(--enable-neon)
    [[ "${ARCH}" == "x86_64" ]] && ASM_FLAGS=(--disable-asm --disable-neon)

    local WORK_DIR="${BUILD_DIR}/work/${KEY}"
    rm -rf "${WORK_DIR}"
    mkdir -p "${WORK_DIR}"
    cd "${WORK_DIR}"

    # Set pkg-config path so FFmpeg's configure can find dav1d
    export PKG_CONFIG_PATH="${DAV1D_DIR}/lib/pkgconfig:${ZIMG_DIR}/lib/pkgconfig:${ZVBI_DIR}/lib/pkgconfig"

    "${FFMPEG_SRC}/configure" \
        --prefix="${INSTALL_DIR}" \
        --enable-cross-compile \
        --target-os=darwin \
        --arch="${ARCH}" \
        --cc="/usr/bin/clang" \
        --extra-cflags="${CFLAGS}" \
        --extra-ldflags="${LDFLAGS}" \
        "${ASM_FLAGS[@]}" \
        "${COMMON_FLAGS[@]}" \
        2>&1 | tail -5

    make -j$(sysctl -n hw.ncpu) 2>&1 | tail -3
    make install 2>&1 | tail -3

    echo "✓ FFmpeg ${KEY} → ${INSTALL_DIR}"
}

make_framework() {
    local LIB="$1" FW="$2" PLATFORM="$3"
    shift 3
    local KEYS=("$@")

    local FW_DIR="${BUILD_DIR}/frameworks/${PLATFORM}/${FW}.framework"
    rm -rf "${FW_DIR}"
    mkdir -p "${FW_DIR}/Headers" "${FW_DIR}/Modules"

    # Headers from first arch
    local HEADER_SRC="${BUILD_DIR}/thin/${KEYS[1]}/include/${LIB}"
    # For dav1d, headers are in a different location
    [[ "${LIB}" == "dav1d" ]] && HEADER_SRC="${BUILD_DIR}/dav1d-thin/${KEYS[1]}/include/dav1d"
    # For zimg, headers install directly under include/
    [[ "${LIB}" == "zimg" ]] && HEADER_SRC="${BUILD_DIR}/zimg-thin/${KEYS[1]}/include"

    if [[ "${LIB}" == "zimg" ]]; then
        # Ship only the C API header; zimg++.hpp would put C++ into the
        # framework module. No Swift consumer imports Libzimg directly
        # (it is a link-only dependency of libavfilter).
        cp "${HEADER_SRC}/zimg.h" "${FW_DIR}/Headers/"
    elif [[ -d "${HEADER_SRC}" ]]; then
        cp -R "${HEADER_SRC}/"* "${FW_DIR}/Headers/"
    fi

    # Remove platform-specific hwcontext headers (FFmpeg only)
    if [[ "${LIB}" == lib* ]]; then
        rm -f "${FW_DIR}/Headers/hwcontext_amf.h" \
              "${FW_DIR}/Headers/hwcontext_cuda.h" \
              "${FW_DIR}/Headers/hwcontext_d3d11va.h" \
              "${FW_DIR}/Headers/hwcontext_d3d12va.h" \
              "${FW_DIR}/Headers/hwcontext_drm.h" \
              "${FW_DIR}/Headers/hwcontext_dxva2.h" \
              "${FW_DIR}/Headers/hwcontext_mediacodec.h" \
              "${FW_DIR}/Headers/hwcontext_oh.h" \
              "${FW_DIR}/Headers/hwcontext_opencl.h" \
              "${FW_DIR}/Headers/hwcontext_qsv.h" \
              "${FW_DIR}/Headers/hwcontext_vaapi.h" \
              "${FW_DIR}/Headers/hwcontext_vdpau.h" \
              "${FW_DIR}/Headers/hwcontext_vulkan.h"
    fi

    # Lipo
    local INPUTS=()
    for K in "${KEYS[@]}"; do
        local LIB_PATH
        if [[ "${LIB}" == "dav1d" ]]; then
            LIB_PATH="${BUILD_DIR}/dav1d-thin/${K}/lib/libdav1d.a"
        elif [[ "${LIB}" == "zimg" ]]; then
            LIB_PATH="${BUILD_DIR}/zimg-thin/${K}/lib/libzimg.a"
        else
            LIB_PATH="${BUILD_DIR}/thin/${K}/lib/${LIB}.a"
        fi
        INPUTS+=("${LIB_PATH}")
    done
    lipo -create "${INPUTS[@]}" -output "${FW_DIR}/${FW}"

    # Module map
    cat > "${FW_DIR}/Modules/module.modulemap" << EOF
framework module ${FW} [system] {
    umbrella "."
    exclude header "d3d11va.h"
    exclude header "d3d12va.h"
    exclude header "dxva2.h"
    exclude header "qsv.h"
    exclude header "vdpau.h"
    export *
}
EOF
    # Info.plist: App Store submission rejects bundles missing
    # CFBundleShortVersionString or MinimumOSVersion (ITMS-90057,
    # ITMS-90360), and ALSO rejects when an embedded framework's
    # MinimumOSVersion is *lower* than the host app's deployment
    # target (ITMS-90208). We pick floors that match the apps that
    # actually consume this build (JellySeeTV is tvOS 26+).
    local MIN_OS
    case "${PLATFORM}" in
        ios|ios-sim)   MIN_OS="26.0" ;;
        tvos|tvos-sim) MIN_OS="26.0" ;;
        macos)         MIN_OS="14.0" ;;
        *)             MIN_OS="26.0" ;;
    esac

    cat > "${FW_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>${FW}</string>
<key>CFBundleIdentifier</key><string>com.aetherengine.${FW}</string>
<key>CFBundleName</key><string>${FW}</string>
<key>CFBundleVersion</key><string>1.0</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundlePackageType</key><string>FMWK</string>
<key>MinimumOSVersion</key><string>${MIN_OS}</string>
</dict></plist>
EOF

    # macOS requires the versioned ("deep") framework bundle layout, with the
    # binary/Headers/Modules under Versions/A and Info.plist in
    # Versions/A/Resources. iOS/tvOS use shallow bundles (everything at the
    # root), which is what we built above. Restructure only the macOS
    # framework, otherwise Xcode 15+/26 rejects it during embedded-framework
    # validation: "contains Info.plist, expected
    # Versions/Current/Resources/Info.plist since the platform does not use
    # shallow bundles".
    if [[ "${PLATFORM}" == "macos" ]]; then
        local V="${FW_DIR}/Versions/A"
        mkdir -p "${V}/Resources"
        mv "${FW_DIR}/${FW}"      "${V}/${FW}"
        mv "${FW_DIR}/Headers"    "${V}/Headers"
        mv "${FW_DIR}/Modules"    "${V}/Modules"
        mv "${FW_DIR}/Info.plist" "${V}/Resources/Info.plist"
        ln -s "A"                          "${FW_DIR}/Versions/Current"
        ln -s "Versions/Current/${FW}"     "${FW_DIR}/${FW}"
        ln -s "Versions/Current/Headers"   "${FW_DIR}/Headers"
        ln -s "Versions/Current/Modules"   "${FW_DIR}/Modules"
        ln -s "Versions/Current/Resources" "${FW_DIR}/Resources"
    fi
}

make_xcframeworks() {
    echo ""
    echo "━━━ Creating XCFrameworks ━━━"

    local PAIRS=("libavcodec:Libavcodec" "libavformat:Libavformat" "libavutil:Libavutil" "libswresample:Libswresample" "libswscale:Libswscale" "libavfilter:Libavfilter" "dav1d:Libdav1d" "zimg:Libzimg")

    for PAIR in "${PAIRS[@]}"; do
        local LIB="${PAIR%%:*}"
        local FW="${PAIR##*:}"

        make_framework "$LIB" "$FW" "ios"          ios-arm64
        make_framework "$LIB" "$FW" "isimulator"   isimulator-arm64 isimulator-x86_64
        make_framework "$LIB" "$FW" "tvos"         tvos-arm64
        make_framework "$LIB" "$FW" "tvsimulator"  tvsimulator-arm64 tvsimulator-x86_64
        make_framework "$LIB" "$FW" "macos"        macos-arm64 macos-x86_64

        local XCF="${OUTPUT_DIR}/${FW}.xcframework"
        rm -rf "${XCF}"

        echo "  → ${FW}.xcframework"
        xcodebuild -create-xcframework \
            -framework "${BUILD_DIR}/frameworks/ios/${FW}.framework" \
            -framework "${BUILD_DIR}/frameworks/isimulator/${FW}.framework" \
            -framework "${BUILD_DIR}/frameworks/tvos/${FW}.framework" \
            -framework "${BUILD_DIR}/frameworks/tvsimulator/${FW}.framework" \
            -framework "${BUILD_DIR}/frameworks/macos/${FW}.framework" \
            -output "${XCF}" 2>&1 | tail -1
        echo "  ✓ ${FW}.xcframework"
    done
}

# ─────────────────────────────────────────────────────────

if [[ "$1" == "clean" ]]; then
    echo "Cleaning..."
    rm -rf "${BUILD_DIR}" "${OUTPUT_DIR}/"*.xcframework
    echo "✓ Clean"
    exit 0
fi

# `package` mode skips fetch + compile and only re-runs the
# framework + xcframework packaging steps using whatever's already
# in build/thin and build/dav1d-thin. Useful when the only change
# is to header-exclusion lists or framework Info.plist values, so
# we don't burn a full multi-arch FFmpeg rebuild.
if [[ "$1" == "package" ]]; then
    rm -rf "${BUILD_DIR}/frameworks" "${OUTPUT_DIR}/"*.xcframework 2>/dev/null || true
    make_xcframeworks
    echo ""
    echo "✓ Repackage complete"
    exit 0
fi

echo "╔══════════════════════════════════════╗"
echo "║  FFmpegBuild: FFmpeg + dav1d (AV1)  ║"
echo "║  VideoToolbox HW + Metal ready      ║"
echo "╚══════════════════════════════════════╝"

fetch_ffmpeg
fetch_dav1d
fetch_zimg
fetch_zvbi

# Build dav1d for all platforms first
build_dav1d_one ios-arm64          iphoneos         arm64  arm64-apple-ios16.0                    16.0
build_dav1d_one isimulator-arm64   iphonesimulator  arm64  arm64-apple-ios16.0-simulator          16.0
build_dav1d_one isimulator-x86_64  iphonesimulator  x86_64 x86_64-apple-ios16.0-simulator         16.0
build_dav1d_one tvos-arm64         appletvos        arm64  arm64-apple-tvos16.0                   16.0
build_dav1d_one tvsimulator-arm64  appletvsimulator arm64  arm64-apple-tvos16.0-simulator         16.0
build_dav1d_one tvsimulator-x86_64 appletvsimulator x86_64 x86_64-apple-tvos16.0-simulator        16.0
build_dav1d_one macos-arm64        macosx           arm64  arm64-apple-macos14.0                  14.0
build_dav1d_one macos-x86_64       macosx           x86_64 x86_64-apple-macos14.0                 14.0

# Build zimg for all platforms (FFmpeg's configure must find it)
build_zimg_one ios-arm64          iphoneos         arm64  arm64-apple-ios16.0                    16.0
build_zimg_one isimulator-arm64   iphonesimulator  arm64  arm64-apple-ios16.0-simulator          16.0
build_zimg_one isimulator-x86_64  iphonesimulator  x86_64 x86_64-apple-ios16.0-simulator         16.0
build_zimg_one tvos-arm64         appletvos        arm64  arm64-apple-tvos16.0                   16.0
build_zimg_one tvsimulator-arm64  appletvsimulator arm64  arm64-apple-tvos16.0-simulator         16.0
build_zimg_one tvsimulator-x86_64 appletvsimulator x86_64 x86_64-apple-tvos16.0-simulator        16.0
build_zimg_one macos-arm64        macosx           arm64  arm64-apple-macos14.0                  14.0
build_zimg_one macos-x86_64       macosx           x86_64 x86_64-apple-macos14.0                 14.0

# Build libzvbi for all platforms (FFmpeg's configure must find it for the teletext decoder)
build_zvbi_one ios-arm64          iphoneos         arm64  arm64-apple-ios16.0                    16.0
build_zvbi_one isimulator-arm64   iphonesimulator  arm64  arm64-apple-ios16.0-simulator          16.0
build_zvbi_one isimulator-x86_64  iphonesimulator  x86_64 x86_64-apple-ios16.0-simulator         16.0
build_zvbi_one tvos-arm64         appletvos        arm64  arm64-apple-tvos16.0                   16.0
build_zvbi_one tvsimulator-arm64  appletvsimulator arm64  arm64-apple-tvos16.0-simulator         16.0
build_zvbi_one tvsimulator-x86_64 appletvsimulator x86_64 x86_64-apple-tvos16.0-simulator        16.0
build_zvbi_one macos-arm64        macosx           arm64  arm64-apple-macos14.0                  14.0
build_zvbi_one macos-x86_64       macosx           x86_64 x86_64-apple-macos14.0                 14.0

# Build FFmpeg (links against dav1d)
build_one ios-arm64          iphoneos         arm64  arm64-apple-ios16.0                    16.0
build_one isimulator-arm64   iphonesimulator  arm64  arm64-apple-ios16.0-simulator          16.0
build_one isimulator-x86_64  iphonesimulator  x86_64 x86_64-apple-ios16.0-simulator         16.0
build_one tvos-arm64         appletvos        arm64  arm64-apple-tvos16.0                   16.0
build_one tvsimulator-arm64  appletvsimulator arm64  arm64-apple-tvos16.0-simulator         16.0
build_one tvsimulator-x86_64 appletvsimulator x86_64 x86_64-apple-tvos16.0-simulator        16.0
build_one macos-arm64        macosx           arm64  arm64-apple-macos14.0                  14.0
build_one macos-x86_64       macosx           x86_64 x86_64-apple-macos14.0                 14.0

make_xcframeworks

echo ""
echo "╔══════════════════════════════════════╗"
echo "║  ✓ Build complete!                   ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Sizes:"
for xcf in "${OUTPUT_DIR}"/*.xcframework; do
    [[ -d "$xcf" ]] && echo "  $(du -sh "$xcf" | cut -f1)  $(basename $xcf)"
done
