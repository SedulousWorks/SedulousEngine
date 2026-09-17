# joltc-Beef's native build.
#
# The vendored joltc/ is left EXACTLY as upstream ships it: this adds the shape cooking
# seam (joltc_beef.cpp) to its own library target rather than editing the vendored tree,
# so pulling a newer joltc down is a directory replacement and nothing else.

cmake_minimum_required(VERSION 3.16 FATAL_ERROR)

project(joltc_beef CXX C)

# joltc decides its defaults from whether it is the top level project. It no longer is, so
# say so explicitly: without this it would build STATIC, and the Beef side links a shared
# library.
#
# Overridable, because wasm has no shared libraries: the wasm build passes OFF and links the
# static archive instead. A -D defines the cache entry, which makes this guard skip the set.
if(NOT DEFINED JPH_MASTER_PROJECT)
  set(JPH_MASTER_PROJECT ON)
endif()

# Neither ships, and building them costs a fetch of the test framework.
set(JPH_SAMPLES OFF CACHE BOOL "" FORCE)
set(JPH_TESTS OFF CACHE BOOL "" FORCE)

add_subdirectory(joltc)

target_sources(joltc PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/joltc_beef.cpp)
target_include_directories(joltc PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>)
