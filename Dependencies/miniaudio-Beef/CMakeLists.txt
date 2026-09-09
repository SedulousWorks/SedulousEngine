cmake_minimum_required(VERSION 3.15)

project(miniaudio)

# Two translation units: the vendored implementation, and the handle surface the Beef
# binding calls. stb_vorbis comes from the sibling dependency rather than a second copy,
# so there is exactly one of it in the tree; miniaudio compiles it into ITS lib, so an
# application must not also link stb_vorbis-Beef.
add_library(miniaudio_static STATIC miniaudio_stub.c miniaudio_beef.c)

set_property(TARGET miniaudio_static PROPERTY
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set_source_files_properties(miniaudio_stub.c PROPERTIES LANGUAGE C)
set_source_files_properties(miniaudio_beef.c PROPERTIES LANGUAGE C)

target_include_directories(miniaudio_static PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/../stb_vorbis-Beef/stb_vorbis)

set(CMAKE_C_STANDARD 11)
set(CMAKE_BUILD_TYPE RelWithDebInfo)

if(UNIX AND NOT APPLE)
    find_package(Threads REQUIRED)
    target_link_libraries(miniaudio_static PUBLIC Threads::Threads ${CMAKE_DL_LIBS} m)
endif()

set_target_properties(miniaudio_static PROPERTIES OUTPUT_NAME miniaudio)
