cmake_minimum_required(VERSION 3.15)
project(astcenc VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Static CRT on Windows, as the other bindings do: avoids needing ucrt.lib at link time.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

# Debug info in the OBJECTS rather than a shared compiler PDB.
#
# MSVC defaults to /Zi, which puts every translation unit's debug info in ONE .pdb beside the
# archive. A dozen translation units compiling in parallel then serialise their writes
# through mspdbsrv, and when that handshake fails the build dies with
# "C1090: PDB API call failed". /Z7 puts the debug info in each .obj, so there is no shared
# file to contend over.
#
# It also makes the archive SELF CONTAINED, which matters more: build-native copies the .lib
# into dist/ and leaves the .pdb behind in the build tree, so an external PDB would not travel
# with the library a consumer actually links.
#
# Written as a flag rewrite rather than CMAKE_MSVC_DEBUG_INFORMATION_FORMAT because that needs
# CMake 3.25 and policy CMP0141; this file supports 3.15.
if(MSVC)
    foreach(lang C CXX)
        foreach(config DEBUG RELWITHDEBINFO)
            string(REPLACE "/Zi" "/Z7"
                   CMAKE_${lang}_FLAGS_${config} "${CMAKE_${lang}_FLAGS_${config}}")
        endforeach()
    endforeach()
endif()

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
