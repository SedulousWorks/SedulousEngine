cmake_minimum_required(VERSION 3.15)
project(bc7enc-c VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Static CRT on Windows, as the other bindings do: avoids needing ucrt.lib at link time.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

# Debug info in the OBJECTS rather than a shared compiler PDB.
#
# MSVC defaults to /Zi, which puts every translation unit's debug info in ONE .pdb beside the
# archive. Four translation units compiling in parallel then serialise their writes through
# mspdbsrv, and when that handshake fails the build dies with
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

set(BC7ENC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../bc7enc)

# ONE archive rather than the wrapper and the upstream core separately: the whole of the
# vendored encoder is three translation units, so merging them costs nothing and spares the
# BeefProj an ordered pair of LibPaths.
add_library(bc7enc-c STATIC
    ${CMAKE_CURRENT_SOURCE_DIR}/bc7enc_c.cpp
    ${BC7ENC_DIR}/bc7enc.cpp
    ${BC7ENC_DIR}/rgbcx.cpp
    ${BC7ENC_DIR}/bc7decomp.cpp)

target_include_directories(bc7enc-c
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    PRIVATE
        ${BC7ENC_DIR})

# Position independent, since a consumer may end up in a shared object.
set_target_properties(bc7enc-c PROPERTIES POSITION_INDEPENDENT_CODE ON
                                          OUTPUT_NAME bc7enc-c)
