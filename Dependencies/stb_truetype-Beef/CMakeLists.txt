cmake_minimum_required(VERSION 3.15)

project(stb_truetype)

add_library(stb_truetype_static STATIC stb_truetype_stub.c)

set_property(TARGET stb_truetype_static PROPERTY
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set_source_files_properties(stb_truetype_stub.c PROPERTIES LANGUAGE C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_BUILD_TYPE RelWithDebInfo)

set_target_properties(stb_truetype_static PROPERTIES OUTPUT_NAME stb_truetype)