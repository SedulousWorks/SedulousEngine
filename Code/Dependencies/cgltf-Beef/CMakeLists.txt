cmake_minimum_required(VERSION 3.15)

project(cgltf)

add_library(cgltf_static STATIC cgltf_stub.c)

set_property(TARGET cgltf_static PROPERTY
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set_source_files_properties(cgltf_stub.c PROPERTIES LANGUAGE C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_BUILD_TYPE RelWithDebInfo)

set_target_properties(cgltf_static PROPERTIES OUTPUT_NAME cgltf)