#!/usr/bin/env bash
# Linux counterpart of build-native.ps1.
# Builds the native cimgui static library and copies it into dist/ so the
# Beef project's [Configs.*.Linux64] LibPaths can find it.
set -euo pipefail

cd "$(dirname "$0")"

option="${1:-help}"
target="${2:-ALL}"

print_help() {
    echo "Arguments:"
    echo "  make [DEBUG|RELEASE|ALL]... configure cmake"
    echo "  build [DEBUG|RELEASE|ALL]... build libraries (also copies to dist/)"
    echo "  clean....................... remove build directories"
}

configure() {
    local cfg="$1" dir="$2"
    echo "Configuring $cfg..."
    cmake -S . -B "$dir" -G Ninja -DCMAKE_BUILD_TYPE="$cfg"
}

build() {
    local cfg="$1" dir="$2" distdir="$3"
    if [ ! -d "$dir" ]; then
        echo "$cfg build directory missing. Run 'make $cfg' first."
        return
    fi
    echo "Building $cfg..."
    cmake --build "$dir"
    mkdir -p "$distdir"
    cp -f "$dir/libcimgui.a" "$distdir/libcimgui.a"
    echo "Copied libcimgui.a -> $distdir"
}

case "$option" in
    make)
        [ "$target" = "DEBUG" ]   || [ "$target" = "ALL" ] && configure Debug   build-linux-debug
        [ "$target" = "RELEASE" ] || [ "$target" = "ALL" ] && configure Release build-linux-release
        ;;
    build)
        [ "$target" = "DEBUG" ]   || [ "$target" = "ALL" ] && build Debug   build-linux-debug   dist/Debug-Linux64
        [ "$target" = "RELEASE" ] || [ "$target" = "ALL" ] && build Release build-linux-release dist/Release-Linux64
        ;;
    clean)
        rm -rf build-linux-debug build-linux-release
        echo "Clean complete."
        ;;
    *)
        print_help
        ;;
esac
