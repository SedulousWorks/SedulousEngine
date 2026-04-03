cmake_minimum_required(VERSION 3.15)

project(dr_libs)

#flac

add_library(dr_flac_static STATIC dr_flac_stub.c)

set_property(TARGET dr_flac_static PROPERTY
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set_source_files_properties(dr_flac_stub.c PROPERTIES LANGUAGE C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_BUILD_TYPE RelWithDebInfo)

set_target_properties(dr_flac_static PROPERTIES OUTPUT_NAME dr_flac)

#mp3

add_library(dr_mp3_static STATIC dr_mp3_stub.c)

set_property(TARGET dr_mp3_static PROPERTY
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set_source_files_properties(dr_mp3_stub.c PROPERTIES LANGUAGE C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_BUILD_TYPE RelWithDebInfo)

set_target_properties(dr_mp3_static PROPERTIES OUTPUT_NAME dr_mp3)

#wav

add_library(dr_wav_static STATIC dr_wav_stub.c)

set_property(TARGET dr_wav_static PROPERTY
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set_source_files_properties(dr_wav_stub.c PROPERTIES LANGUAGE C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_BUILD_TYPE RelWithDebInfo)

set_target_properties(dr_wav_static PROPERTIES OUTPUT_NAME dr_wav)