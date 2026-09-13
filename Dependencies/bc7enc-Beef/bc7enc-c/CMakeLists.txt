cmake_minimum_required(VERSION 3.15)
project(bc7enc-c VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Static CRT on Windows, as the other bindings do: avoids needing ucrt.lib at link time.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

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
