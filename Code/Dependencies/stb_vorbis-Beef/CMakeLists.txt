cmake_minimum_required(VERSION 3.15)

project(stb_vorbis)

add_library(stb_vorbis_static STATIC stb_vorbis_stub.c)

set_property(TARGET stb_vorbis_static PROPERTY
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set_source_files_properties(stb_vorbis_stub.c PROPERTIES LANGUAGE C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_BUILD_TYPE RelWithDebInfo)

set_target_properties(stb_vorbis_static PROPERTIES OUTPUT_NAME stb_vorbis)