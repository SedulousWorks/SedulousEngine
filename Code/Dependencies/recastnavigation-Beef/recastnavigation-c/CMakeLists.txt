cmake_minimum_required(VERSION 3.15)
project(recastnavigation-c VERSION 1.0.0 LANGUAGES CXX)

# C++ standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Use static CRT on Windows (avoids needing ucrt.lib at link time)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

# Build options
option(BUILD_RECAST_C "Build Recast C interface" ON)
option(BUILD_DETOUR_C "Build Detour C interface" ON)
option(BUILD_DETOURCROWD_C "Build DetourCrowd C interface" ON)
option(BUILD_DETOURTILECACHE_C "Build DetourTileCache C interface" ON)
option(BUILD_DEBUGUTILS_C "Build DebugUtils C interface" ON)
option(BUILD_SHARED_LIBS "Build shared libraries (OFF for static)" OFF)

# Output directories
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Include directories for original recastnavigation
set(RECASTNAVIGATION_DIR ${CMAKE_CURRENT_SOURCE_DIR}/recastnavigation)
set(RECAST_INCLUDE_DIR ${RECASTNAVIGATION_DIR}/Recast/Include)
set(DETOUR_INCLUDE_DIR ${RECASTNAVIGATION_DIR}/Detour/Include)
set(DETOURCROWD_INCLUDE_DIR ${RECASTNAVIGATION_DIR}/DetourCrowd/Include)
set(DETOURTILECACHE_INCLUDE_DIR ${RECASTNAVIGATION_DIR}/DetourTileCache/Include)
set(DEBUGUTILS_INCLUDE_DIR ${RECASTNAVIGATION_DIR}/DebugUtils/Include)

# ============================================
# Original Recast library sources
# ============================================
set(RECAST_SOURCES
    ${RECASTNAVIGATION_DIR}/Recast/Source/Recast.cpp
    ${RECASTNAVIGATION_DIR}/Recast/Source/RecastAlloc.cpp
    ${RECASTNAVIGATION_DIR}/Recast/Source/RecastArea.cpp
    ${RECASTNAVIGATION_DIR}/Recast/Source/RecastAssert.cpp
    ${RECASTNAVIGATION_DIR}/Recast/Source/RecastContour.cpp
    ${RECASTNAVIGATION_DIR}/Recast/Source/RecastFilter.cpp
    ${RECASTNAVIGATION_DIR}/Recast/Source/RecastLayers.cpp
    ${RECASTNAVIGATION_DIR}/Recast/Source/RecastMesh.cpp
    ${RECASTNAVIGATION_DIR}/Recast/Source/RecastMeshDetail.cpp
    ${RECASTNAVIGATION_DIR}/Recast/Source/RecastRasterization.cpp
    ${RECASTNAVIGATION_DIR}/Recast/Source/RecastRegion.cpp
)

# ============================================
# Original Detour library sources
# ============================================
set(DETOUR_SOURCES
    ${RECASTNAVIGATION_DIR}/Detour/Source/DetourAlloc.cpp
    ${RECASTNAVIGATION_DIR}/Detour/Source/DetourAssert.cpp
    ${RECASTNAVIGATION_DIR}/Detour/Source/DetourCommon.cpp
    ${RECASTNAVIGATION_DIR}/Detour/Source/DetourNavMesh.cpp
    ${RECASTNAVIGATION_DIR}/Detour/Source/DetourNavMeshBuilder.cpp
    ${RECASTNAVIGATION_DIR}/Detour/Source/DetourNavMeshQuery.cpp
    ${RECASTNAVIGATION_DIR}/Detour/Source/DetourNode.cpp
)

# ============================================
# Original DetourCrowd library sources
# ============================================
set(DETOURCROWD_SOURCES
    ${RECASTNAVIGATION_DIR}/DetourCrowd/Source/DetourCrowd.cpp
    ${RECASTNAVIGATION_DIR}/DetourCrowd/Source/DetourLocalBoundary.cpp
    ${RECASTNAVIGATION_DIR}/DetourCrowd/Source/DetourObstacleAvoidance.cpp
    ${RECASTNAVIGATION_DIR}/DetourCrowd/Source/DetourPathCorridor.cpp
    ${RECASTNAVIGATION_DIR}/DetourCrowd/Source/DetourPathQueue.cpp
    ${RECASTNAVIGATION_DIR}/DetourCrowd/Source/DetourProximityGrid.cpp
)

# ============================================
# Original DetourTileCache library sources
# ============================================
set(DETOURTILECACHE_SOURCES
    ${RECASTNAVIGATION_DIR}/DetourTileCache/Source/DetourTileCache.cpp
    ${RECASTNAVIGATION_DIR}/DetourTileCache/Source/DetourTileCacheBuilder.cpp
)

# ============================================
# Original DebugUtils library sources
# ============================================
set(DEBUGUTILS_SOURCES
    ${RECASTNAVIGATION_DIR}/DebugUtils/Source/DebugDraw.cpp
    ${RECASTNAVIGATION_DIR}/DebugUtils/Source/DetourDebugDraw.cpp
    ${RECASTNAVIGATION_DIR}/DebugUtils/Source/RecastDebugDraw.cpp
    ${RECASTNAVIGATION_DIR}/DebugUtils/Source/RecastDump.cpp
)

# ============================================
# Recast-C
# ============================================
if(BUILD_RECAST_C)
    set(RECAST_C_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/Recast-c/RecastC.cpp
    )

    add_library(Recast-c ${RECAST_SOURCES} ${RECAST_C_SOURCES})

    target_include_directories(Recast-c
        PUBLIC
            ${CMAKE_CURRENT_SOURCE_DIR}/Recast-c
            ${RECAST_INCLUDE_DIR}
    )

    if(BUILD_SHARED_LIBS)
        target_compile_definitions(Recast-c PRIVATE RECAST_C_EXPORTS)
        set_target_properties(Recast-c PROPERTIES
            WINDOWS_EXPORT_ALL_SYMBOLS ON
        )
    else()
        target_compile_definitions(Recast-c PUBLIC RECAST_C_STATIC)
    endif()
endif()

# ============================================
# Detour-C
# ============================================
if(BUILD_DETOUR_C)
    set(DETOUR_C_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/Detour-c/DetourC.cpp
    )

    add_library(Detour-c ${DETOUR_SOURCES} ${DETOUR_C_SOURCES})

    target_include_directories(Detour-c
        PUBLIC
            ${CMAKE_CURRENT_SOURCE_DIR}/Detour-c
            ${DETOUR_INCLUDE_DIR}
    )

    if(BUILD_SHARED_LIBS)
        target_compile_definitions(Detour-c PRIVATE DETOUR_C_EXPORTS)
        set_target_properties(Detour-c PROPERTIES
            WINDOWS_EXPORT_ALL_SYMBOLS ON
        )
    else()
        target_compile_definitions(Detour-c PUBLIC DETOUR_C_STATIC)
    endif()
endif()

# ============================================
# DetourCrowd-C
# ============================================
if(BUILD_DETOURCROWD_C)
    if(NOT BUILD_DETOUR_C)
        message(FATAL_ERROR "DetourCrowd-C requires Detour-C to be enabled")
    endif()

    set(DETOURCROWD_C_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/DetourCrowd-c/DetourCrowdC.cpp
    )

    add_library(DetourCrowd-c ${DETOURCROWD_SOURCES} ${DETOURCROWD_C_SOURCES})

    target_include_directories(DetourCrowd-c
        PUBLIC
            ${CMAKE_CURRENT_SOURCE_DIR}/DetourCrowd-c
            ${CMAKE_CURRENT_SOURCE_DIR}/Detour-c
            ${DETOURCROWD_INCLUDE_DIR}
            ${DETOUR_INCLUDE_DIR}
    )

    target_link_libraries(DetourCrowd-c PUBLIC Detour-c)

    if(BUILD_SHARED_LIBS)
        target_compile_definitions(DetourCrowd-c PRIVATE DETOURCROWD_C_EXPORTS)
        set_target_properties(DetourCrowd-c PROPERTIES
            WINDOWS_EXPORT_ALL_SYMBOLS ON
        )
    else()
        target_compile_definitions(DetourCrowd-c PUBLIC DETOURCROWD_C_STATIC)
    endif()
endif()

# ============================================
# DetourTileCache-C
# ============================================
if(BUILD_DETOURTILECACHE_C)
    if(NOT BUILD_DETOUR_C)
        message(FATAL_ERROR "DetourTileCache-C requires Detour-C to be enabled")
    endif()

    set(DETOURTILECACHE_C_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/DetourTileCache-c/DetourTileCacheC.cpp
    )

    add_library(DetourTileCache-c ${DETOURTILECACHE_SOURCES} ${DETOURTILECACHE_C_SOURCES})

    target_include_directories(DetourTileCache-c
        PUBLIC
            ${CMAKE_CURRENT_SOURCE_DIR}/DetourTileCache-c
            ${CMAKE_CURRENT_SOURCE_DIR}/Detour-c
            ${DETOURTILECACHE_INCLUDE_DIR}
            ${DETOUR_INCLUDE_DIR}
    )

    target_link_libraries(DetourTileCache-c PUBLIC Detour-c)

    if(BUILD_SHARED_LIBS)
        target_compile_definitions(DetourTileCache-c PRIVATE DETOURTILECACHE_C_EXPORTS)
        set_target_properties(DetourTileCache-c PROPERTIES
            WINDOWS_EXPORT_ALL_SYMBOLS ON
        )
    else()
        target_compile_definitions(DetourTileCache-c PUBLIC DETOURTILECACHE_C_STATIC)
    endif()
endif()

# ============================================
# DebugUtils-C
# ============================================
if(BUILD_DEBUGUTILS_C)
    if(NOT BUILD_RECAST_C)
        message(FATAL_ERROR "DebugUtils-C requires Recast-C to be enabled")
    endif()
    if(NOT BUILD_DETOUR_C)
        message(FATAL_ERROR "DebugUtils-C requires Detour-C to be enabled")
    endif()
    if(NOT BUILD_DETOURTILECACHE_C)
        message(FATAL_ERROR "DebugUtils-C requires DetourTileCache-C to be enabled")
    endif()

    set(DEBUGUTILS_C_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/DebugUtils-c/DebugUtilsC.cpp
    )

    add_library(DebugUtils-c ${DEBUGUTILS_SOURCES} ${DEBUGUTILS_C_SOURCES})

    target_include_directories(DebugUtils-c
        PUBLIC
            ${CMAKE_CURRENT_SOURCE_DIR}/DebugUtils-c
            ${CMAKE_CURRENT_SOURCE_DIR}/Recast-c
            ${CMAKE_CURRENT_SOURCE_DIR}/Detour-c
            ${CMAKE_CURRENT_SOURCE_DIR}/DetourTileCache-c
            ${DEBUGUTILS_INCLUDE_DIR}
            ${RECAST_INCLUDE_DIR}
            ${DETOUR_INCLUDE_DIR}
            ${DETOURTILECACHE_INCLUDE_DIR}
    )

    target_link_libraries(DebugUtils-c PUBLIC Recast-c Detour-c DetourTileCache-c)

    if(BUILD_SHARED_LIBS)
        target_compile_definitions(DebugUtils-c PRIVATE DEBUGUTILS_C_EXPORTS)
        set_target_properties(DebugUtils-c PROPERTIES
            WINDOWS_EXPORT_ALL_SYMBOLS ON
        )
    else()
        target_compile_definitions(DebugUtils-c PUBLIC DEBUGUTILS_C_STATIC)
    endif()
endif()

# ============================================
# Combined library (optional)
# ============================================
option(BUILD_COMBINED "Build a single combined library" OFF)

if(BUILD_COMBINED)
    set(COMBINED_SOURCES)
    set(COMBINED_INCLUDES)
    set(COMBINED_DEPS)

    if(BUILD_RECAST_C)
        list(APPEND COMBINED_SOURCES ${RECAST_SOURCES} ${RECAST_C_SOURCES})
        list(APPEND COMBINED_INCLUDES ${CMAKE_CURRENT_SOURCE_DIR}/Recast-c ${RECAST_INCLUDE_DIR})
    endif()

    if(BUILD_DETOUR_C)
        list(APPEND COMBINED_SOURCES ${DETOUR_SOURCES} ${DETOUR_C_SOURCES})
        list(APPEND COMBINED_INCLUDES ${CMAKE_CURRENT_SOURCE_DIR}/Detour-c ${DETOUR_INCLUDE_DIR})
    endif()

    if(BUILD_DETOURCROWD_C)
        list(APPEND COMBINED_SOURCES ${DETOURCROWD_SOURCES} ${DETOURCROWD_C_SOURCES})
        list(APPEND COMBINED_INCLUDES ${CMAKE_CURRENT_SOURCE_DIR}/DetourCrowd-c ${DETOURCROWD_INCLUDE_DIR})
    endif()

    if(BUILD_DETOURTILECACHE_C)
        list(APPEND COMBINED_SOURCES ${DETOURTILECACHE_SOURCES} ${DETOURTILECACHE_C_SOURCES})
        list(APPEND COMBINED_INCLUDES ${CMAKE_CURRENT_SOURCE_DIR}/DetourTileCache-c ${DETOURTILECACHE_INCLUDE_DIR})
    endif()

    if(BUILD_DEBUGUTILS_C)
        list(APPEND COMBINED_SOURCES ${DEBUGUTILS_SOURCES} ${DEBUGUTILS_C_SOURCES})
        list(APPEND COMBINED_INCLUDES ${CMAKE_CURRENT_SOURCE_DIR}/DebugUtils-c ${DEBUGUTILS_INCLUDE_DIR})
    endif()

    if(COMBINED_SOURCES)
        add_library(recastnavigation-c ${COMBINED_SOURCES})

        target_include_directories(recastnavigation-c PUBLIC ${COMBINED_INCLUDES})

        if(BUILD_SHARED_LIBS)
            target_compile_definitions(recastnavigation-c PRIVATE
                RECAST_C_EXPORTS
                DETOUR_C_EXPORTS
                DETOURCROWD_C_EXPORTS
                DETOURTILECACHE_C_EXPORTS
                DEBUGUTILS_C_EXPORTS
            )
            set_target_properties(recastnavigation-c PROPERTIES
                WINDOWS_EXPORT_ALL_SYMBOLS ON
            )
        else()
            target_compile_definitions(recastnavigation-c PUBLIC
                RECAST_C_STATIC
                DETOUR_C_STATIC
                DETOURCROWD_C_STATIC
                DETOURTILECACHE_C_STATIC
                DEBUGUTILS_C_STATIC
            )
        endif()
    endif()
endif()

# ============================================
# Install rules
# ============================================
include(GNUInstallDirs)

# Install headers
if(BUILD_RECAST_C)
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/Recast-c/RecastC.h
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/recastnavigation-c)
    install(TARGETS Recast-c
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()

if(BUILD_DETOUR_C)
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/Detour-c/DetourC.h
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/recastnavigation-c)
    install(TARGETS Detour-c
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()

if(BUILD_DETOURCROWD_C)
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/DetourCrowd-c/DetourCrowdC.h
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/recastnavigation-c)
    install(TARGETS DetourCrowd-c
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()

if(BUILD_DETOURTILECACHE_C)
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/DetourTileCache-c/DetourTileCacheC.h
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/recastnavigation-c)
    install(TARGETS DetourTileCache-c
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()

if(BUILD_DEBUGUTILS_C)
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/DebugUtils-c/DebugUtilsC.h
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/recastnavigation-c)
    install(TARGETS DebugUtils-c
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()

if(BUILD_COMBINED AND TARGET recastnavigation-c)
    install(TARGETS recastnavigation-c
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()

# Print configuration summary
message(STATUS "=== RecastNavigation-C Configuration ===")
message(STATUS "  BUILD_RECAST_C:         ${BUILD_RECAST_C}")
message(STATUS "  BUILD_DETOUR_C:         ${BUILD_DETOUR_C}")
message(STATUS "  BUILD_DETOURCROWD_C:    ${BUILD_DETOURCROWD_C}")
message(STATUS "  BUILD_DETOURTILECACHE_C: ${BUILD_DETOURTILECACHE_C}")
message(STATUS "  BUILD_DEBUGUTILS_C:     ${BUILD_DEBUGUTILS_C}")
message(STATUS "  BUILD_COMBINED:         ${BUILD_COMBINED}")
message(STATUS "  BUILD_SHARED_LIBS:      ${BUILD_SHARED_LIBS}")
message(STATUS "=========================================")
