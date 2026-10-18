cmake_minimum_required(VERSION 3.15)

project(harfbuzz LANGUAGES CXX)

# HarfBuzz from its own amalgamation, with no FreeType, glib, ICU, Graphite or platform
# shaper: its built-in Unicode data and OpenType shaping. The trim is in harfbuzz/README.md.
add_library(harfbuzz_static STATIC harfbuzz/src/harfbuzz.cc)

target_include_directories(harfbuzz_static PUBLIC harfbuzz/src)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Static CRT on Windows, matching the other bindings: avoids needing ucrt.lib at link time.
set_property(TARGET harfbuzz_static PROPERTY
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set_target_properties(harfbuzz_static PROPERTIES OUTPUT_NAME harfbuzz)
