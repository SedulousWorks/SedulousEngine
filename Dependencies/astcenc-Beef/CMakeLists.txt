cmake_minimum_required(VERSION 3.15)
project(astcenc VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Static CRT on Windows, as the other bindings do: avoids needing ucrt.lib at link time.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

option(BUILD_SHARED_LIBS "Build shared libraries (OFF for static)" OFF)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# NO WRAPPER: astcenc.h is already an extern "C" surface, so the Beef side binds it directly
# and this builds the upstream core as it stands.
file(GLOB ASTCENC_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/astcenc/astcenc_*.cpp)
add_library(astcenc STATIC ${ASTCENC_SOURCES})

target_include_directories(astcenc PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/astcenc)

# Forced onto the scalar "none" ISA path so ONE archive builds on every architecture with no
# per-arch source selection. A cook time encoder is never on a frame time path, so the vector
# variants would buy time nobody is waiting on and cost a build matrix.
target_compile_definitions(astcenc PUBLIC
    ASTCENC_SSE=0 ASTCENC_AVX=0 ASTCENC_POPCNT=0 ASTCENC_F16C=0 ASTCENC_NEON=0 ASTCENC_SVE=0)

set_target_properties(astcenc PROPERTIES POSITION_INDEPENDENT_CODE ON
                                         OUTPUT_NAME astcenc)
