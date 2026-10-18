cmake_minimum_required(VERSION 3.15)

project(sheenbidi LANGUAGES C)

# SheenBidi from its own unity source, as C (it does not compile as C++). The trim is in
# README.md.
add_library(sheenbidi_static STATIC sheenbidi/Source/SheenBidi.c)

target_compile_definitions(sheenbidi_static PRIVATE SB_CONFIG_UNITY)
target_include_directories(sheenbidi_static PUBLIC sheenbidi/Headers)
target_include_directories(sheenbidi_static PRIVATE sheenbidi/Source)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Static CRT on Windows, matching the other bindings: avoids needing ucrt.lib at link time.
set_property(TARGET sheenbidi_static PROPERTY
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set_target_properties(sheenbidi_static PROPERTIES OUTPUT_NAME sheenbidi)
