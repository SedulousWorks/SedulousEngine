# The Steam Deck build environment: Ubuntu 22.04, so everything built in it (Beef's runtime,
# the native dependencies, SDL3, the player) asks for glibc 2.35 at most, below the Deck's
# SteamOS. A build on a current desktop asks for 2.43 and does not start there.
#
# Beef itself is NOT in the image: build-steamdeck.sh clones the fork's working branch and
# in-container-build.sh builds it here, cached per commit, so the image only changes when the
# toolchain does.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates wget gnupg lsb-release software-properties-common \
        build-essential git rsync python3 python3-pip pkg-config file binutils \
        autoconf automake libtool texinfo zlib1g-dev libtinfo-dev \
        libvulkan-dev \
        libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxi-dev libxss-dev libxtst-dev \
        libxfixes-dev libxkbcommon-dev libwayland-dev wayland-protocols libdecor-0-dev \
        libasound2-dev libpulse-dev libdbus-1-dev libudev-dev libdrm-dev libgbm-dev libegl1-mesa-dev \
    && rm -rf /var/lib/apt/lists/*

# The host's CMake and Ninja generation (22.04's own CMake is 3.22).
RUN pip3 install --no-cache-dir "cmake==4.2.3" "ninja==1.13.0"

# LLVM 22.1, which Beef's build.sh insists on (llvm-config-22), from apt.llvm.org.
RUN wget -qO /tmp/llvm.sh https://apt.llvm.org/llvm.sh \
    && chmod +x /tmp/llvm.sh && /tmp/llvm.sh 22 \
    && apt-get install -y --no-install-recommends llvm-22-dev \
    && rm -f /tmp/llvm.sh && rm -rf /var/lib/apt/lists/*

# BeefBuild links through the clang++ on PATH when there is one, as on the host; CMake builds
# (Beef's own runtime, the dependencies, SDL) keep the system GCC, as on the host too.
RUN ln -sf /usr/bin/clang-22 /usr/local/bin/clang && ln -sf /usr/bin/clang++-22 /usr/local/bin/clang++

# SDL3, the release the host has, installed where SDL3-Beef's LibPaths look. Shared, and shipped
# beside the player: SDL loads X11, Wayland and the audio backends itself at run time, so its
# own needs stay small.
ARG SDL_VERSION=3.4.2
RUN wget -qO /tmp/sdl.tar.gz https://github.com/libsdl-org/SDL/releases/download/release-${SDL_VERSION}/SDL3-${SDL_VERSION}.tar.gz \
    && tar -xzf /tmp/sdl.tar.gz -C /tmp \
    && cmake -S /tmp/SDL3-${SDL_VERSION} -B /tmp/sdl-build -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib/x86_64-linux-gnu \
        -DSDL_SHARED=ON -DSDL_STATIC=OFF -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF \
    && cmake --build /tmp/sdl-build && cmake --install /tmp/sdl-build \
    && rm -rf /tmp/sdl.tar.gz /tmp/SDL3-${SDL_VERSION} /tmp/sdl-build

WORKDIR /work
