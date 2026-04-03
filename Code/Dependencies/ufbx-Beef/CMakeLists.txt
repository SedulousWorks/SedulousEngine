cmake_minimum_required(VERSION 3.15)

project(ufbx)

add_library(ufbx_static STATIC ufbx/ufbx.c)

set_property(TARGET ufbx_static PROPERTY
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set_source_files_properties(ufbx/ufbx.c PROPERTIES LANGUAGE C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_BUILD_TYPE RelWithDebInfo)

set_target_properties(ufbx_static PROPERTIES OUTPUT_NAME ufbx)
