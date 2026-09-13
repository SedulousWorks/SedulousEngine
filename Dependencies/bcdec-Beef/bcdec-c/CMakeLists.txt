cmake_minimum_required(VERSION 3.15)
project(bcdec-c VERSION 1.0.0 LANGUAGES C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Static CRT on Windows, as the other bindings do: avoids needing ucrt.lib at link time.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

option(BUILD_SHARED_LIBS "Build shared libraries (OFF for static)" OFF)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# NOT a wrapper, just the one translation unit a header-only library needs: bcdec's own
# declarations are already plain C, so the Beef side binds them as they stand.
add_library(bcdec-c STATIC ${CMAKE_CURRENT_SOURCE_DIR}/bcdec_c.c)

target_include_directories(bcdec-c PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../bcdec)

set_target_properties(bcdec-c PROPERTIES POSITION_INDEPENDENT_CODE ON
                                         OUTPUT_NAME bcdec-c)
