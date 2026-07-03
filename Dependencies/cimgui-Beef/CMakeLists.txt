cmake_minimum_required(VERSION 3.15)
cmake_policy(SET CMP0091 NEW)
project(cimgui)

set(CMAKE_CXX_STANDARD 11)

add_library(cimgui STATIC
    cimgui/cimgui.cpp
    cimgui/imgui/imgui.cpp
    cimgui/imgui/imgui_draw.cpp
    cimgui/imgui/imgui_demo.cpp
    cimgui/imgui/imgui_widgets.cpp
    cimgui/imgui/imgui_tables.cpp
)

target_include_directories(cimgui PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/cimgui
    ${CMAKE_CURRENT_SOURCE_DIR}/cimgui/imgui
)

# Static CRT (/MT for Release, /MTd for Debug)
set_property(TARGET cimgui PROPERTY
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

# Static library - no dllexport
target_compile_definitions(cimgui PUBLIC
    CIMGUI_NO_EXPORT
    IMGUI_DISABLE_OBSOLETE_FUNCTIONS=1
)

# cimconfig.h lives in cimgui/ dir, one level up from imgui/
add_definitions("-DIMGUI_USER_CONFIG=\"../cimconfig.h\"")

set_target_properties(cimgui PROPERTIES OUTPUT_NAME cimgui)

if(WIN32)
    target_link_libraries(cimgui imm32)
endif()
