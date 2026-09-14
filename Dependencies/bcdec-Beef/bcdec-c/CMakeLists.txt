cmake_minimum_required(VERSION 3.15)
project(bcdec-c VERSION 1.0.0 LANGUAGES C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Static CRT on Windows, as the other bindings do: avoids needing ucrt.lib at link time.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

# Debug info in the OBJECTS rather than a shared compiler PDB.
#
# MSVC defaults to /Zi, which puts every translation unit's debug info in ONE .pdb beside the
# archive. One translation unit today, but any that are added compile in parallel and then
# serialise their writes through mspdbsrv, and when that handshake fails the build dies with
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

# NOT a wrapper, just the one translation unit a header-only library needs: bcdec's own
# declarations are already plain C, so the Beef side binds them as they stand.
add_library(bcdec-c STATIC ${CMAKE_CURRENT_SOURCE_DIR}/bcdec_c.c)

target_include_directories(bcdec-c PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../bcdec)

set_target_properties(bcdec-c PROPERTIES POSITION_INDEPENDENT_CODE ON
                                         OUTPUT_NAME bcdec-c)
