cmake_minimum_required(VERSION 3.15)
project(msdfgen-c VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Static CRT on Windows, as the other bindings do: avoids needing ucrt.lib at link time.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

option(BUILD_SHARED_LIBS "Build shared libraries (OFF for static)" OFF)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# CORE ONLY. The ext/ half wants FreeType, TinyXML and libpng; a caller already has its
# own font loading and image IO, so pulling those in would buy nothing and cost three
# dependencies. Standalone and vcpkg off for the same reason.
set(MSDFGEN_CORE_ONLY        ON  CACHE BOOL "" FORCE)
set(MSDFGEN_BUILD_STANDALONE OFF CACHE BOOL "" FORCE)
set(MSDFGEN_USE_OPENMP       OFF CACHE BOOL "" FORCE)
set(MSDFGEN_USE_SKIA         OFF CACHE BOOL "" FORCE)
set(MSDFGEN_USE_VCPKG        OFF CACHE BOOL "" FORCE)
set(MSDFGEN_INSTALL          OFF CACHE BOOL "" FORCE)

# msdfgen 1.12 declares cmake_minimum_required below what current CMake accepts without
# it; the same shim goes around the add_subdirectory.
set(CMAKE_POLICY_VERSION_MINIMUM 3.5)
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../msdfgen ${CMAKE_BINARY_DIR}/msdfgen)
unset(CMAKE_POLICY_VERSION_MINIMUM)

# Two archives, as recastnavigation-c ships five: the wrapper here and msdfgen-core beside
# it. Merging them would need $<TARGET_OBJECTS> on a static library, which is CMake 3.21,
# above the 3.15 the other bindings build against. The BeefProj lists both, wrapper first,
# so the link order is stated rather than inferred.
add_library(msdfgen-c STATIC ${CMAKE_CURRENT_SOURCE_DIR}/msdfgen_c.cpp)
target_link_libraries(msdfgen-c PUBLIC msdfgen-core)

target_include_directories(msdfgen-c
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/../msdfgen)

if(BUILD_SHARED_LIBS)
    target_compile_definitions(msdfgen-c PRIVATE MSDFGEN_C_EXPORTS)
    set_target_properties(msdfgen-c PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
else()
    target_compile_definitions(msdfgen-c PUBLIC MSDFGEN_C_STATIC)
endif()

set_target_properties(msdfgen-c PROPERTIES OUTPUT_NAME msdfgen-c)
