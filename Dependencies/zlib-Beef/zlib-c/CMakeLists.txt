cmake_minimum_required(VERSION 3.15)
project(zlib-c VERSION 1.3.2 LANGUAGES C)

# Static CRT on Windows, as the other bindings do: avoids needing ucrt.lib at link time.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

set(ZLIB_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../zlib)

# The library's sources only (no gzip file functions: zlib/README.vendored.md), upstream's
# zconf.h unedited. No wrapper: zlib's interface is plain C whose stream layout is its ABI, so
# src/Zlib.bf binds it directly.
add_library(zlib-c STATIC
    ${ZLIB_DIR}/adler32.c ${ZLIB_DIR}/compress.c ${ZLIB_DIR}/crc32.c ${ZLIB_DIR}/deflate.c
    ${ZLIB_DIR}/infback.c ${ZLIB_DIR}/inffast.c ${ZLIB_DIR}/inflate.c ${ZLIB_DIR}/inftrees.c
    ${ZLIB_DIR}/trees.c ${ZLIB_DIR}/uncompr.c ${ZLIB_DIR}/zutil.c)
target_include_directories(zlib-c PUBLIC ${ZLIB_DIR})

# Every symbol z_-prefixed (z_inflate and so on), so another zlib in the process (a shared
# library loaded beside the engine, a browser's runtime) is never confused with this one.
target_compile_definitions(zlib-c PUBLIC Z_PREFIX)
if(MSVC)
    target_compile_definitions(zlib-c PRIVATE _CRT_SECURE_NO_DEPRECATE _CRT_NONSTDC_NO_DEPRECATE)
endif()

# Position independent, since a consumer may end up in a shared object.
set_target_properties(zlib-c PROPERTIES POSITION_INDEPENDENT_CODE ON
                                        OUTPUT_NAME zlib-c)
