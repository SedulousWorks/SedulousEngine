cmake_minimum_required(VERSION 3.15)

project(nuklear C)

add_library(nuklear_static STATIC nuklear_stub.c)

# Use static runtime library (/MT for Release, /MTd for Debug)
set_property(TARGET nuklear_static PROPERTY
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set_source_files_properties(nuklear_stub.c PROPERTIES LANGUAGE C)

set(CMAKE_C_STANDARD 11)

set_target_properties(nuklear_static PROPERTIES OUTPUT_NAME nuklear)
