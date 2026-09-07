cmake_minimum_required(VERSION 3.15)

project(meshoptimizer LANGUAGES CXX)

# The vendored subset only: index and vertex optimisation, simplification, and the
# analyzers. No codecs, clusterizer, meshlets or stripifier. A binding must declare only
# what these translation units define, or the first call to anything else is a link error.
add_library(meshoptimizer_static STATIC
    meshoptimizer/allocator.cpp
    meshoptimizer/indexgenerator.cpp
    meshoptimizer/indexanalyzer.cpp
    meshoptimizer/rasterizer.cpp
    meshoptimizer/vcacheoptimizer.cpp
    meshoptimizer/overdrawoptimizer.cpp
    meshoptimizer/vfetchoptimizer.cpp
    meshoptimizer/simplifier.cpp)

target_include_directories(meshoptimizer_static PUBLIC meshoptimizer)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Static CRT on Windows, matching the other bindings: avoids needing ucrt.lib at link time.
set_property(TARGET meshoptimizer_static PROPERTY
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set_target_properties(meshoptimizer_static PROPERTIES OUTPUT_NAME meshoptimizer)
