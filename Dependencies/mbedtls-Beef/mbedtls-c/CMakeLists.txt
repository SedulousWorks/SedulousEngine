cmake_minimum_required(VERSION 3.15)
project(mbedtls-c VERSION 1.0.0 LANGUAGES C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Static CRT on Windows, as the other bindings do: avoids needing ucrt.lib at link time.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

# Debug info in the OBJECTS rather than a shared compiler PDB (/Z7, not /Zi): parallel units
# contend over one .pdb through mspdbsrv ("C1090: PDB API call failed"), and the archive that
# build-native copies into dist/ carries its own debug info. A flag rewrite rather than
# CMAKE_MSVC_DEBUG_INFORMATION_FORMAT, which needs CMake 3.25; this file supports 3.15.
if(MSVC)
    foreach(config DEBUG RELWITHDEBINFO)
        string(REPLACE "/Zi" "/Z7" CMAKE_C_FLAGS_${config} "${CMAKE_C_FLAGS_${config}}")
    endforeach()
endif()

option(BUILD_SHARED_LIBS "Build shared libraries (OFF for static)" OFF)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

set(MBEDTLS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../mbedtls)
set(TFPSA_DIR ${MBEDTLS_DIR}/tf-psa-crypto)

# The source list upstream's own CMake configures with its default configuration (no defines:
# the configuration is its headers, include/mbedtls/mbedtls_config.h and
# tf-psa-crypto/include/psa/crypto_config.h), its generated sources as the release ships them (no
# Python at build time). Everest as upstream builds it: the joined unit picks the 128-bit
# Curve25519 where the compiler has the type and the portable one elsewhere (MSVC), and its parts
# never build alone (Hacl_Curve25519.c alone is not MSVC C).
file(GLOB MBEDTLS_SOURCES
    ${MBEDTLS_DIR}/library/*.c
    ${TFPSA_DIR}/core/*.c
    ${TFPSA_DIR}/platform/*.c
    ${TFPSA_DIR}/utilities/*.c
    ${TFPSA_DIR}/extras/*.c
    ${TFPSA_DIR}/drivers/builtin/src/*.c
    ${TFPSA_DIR}/drivers/p256-m/*.c
    ${TFPSA_DIR}/drivers/p256-m/p256-m/*.c
    ${TFPSA_DIR}/drivers/pqcp/src/*.c)
list(APPEND MBEDTLS_SOURCES
    ${TFPSA_DIR}/drivers/everest/library/Hacl_Curve25519_joined.c
    ${TFPSA_DIR}/drivers/everest/library/x25519.c)

# ONE archive, the wrapper and the library together, so the BeefProj names one LibPath.
add_library(mbedtls-c STATIC
    ${CMAKE_CURRENT_SOURCE_DIR}/mbedtls_c.c
    ${MBEDTLS_SOURCES})

target_include_directories(mbedtls-c
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
    PRIVATE
        ${MBEDTLS_DIR}/include
        ${TFPSA_DIR}/include
        ${TFPSA_DIR}/drivers/builtin/include
        ${TFPSA_DIR}/drivers/everest/include
        ${TFPSA_DIR}/drivers/pqcp/include
        ${MBEDTLS_DIR}/library
        ${TFPSA_DIR}/core
        ${TFPSA_DIR}/dispatch
        ${TFPSA_DIR}/extras
        ${TFPSA_DIR}/platform
        ${TFPSA_DIR}/utilities
        ${TFPSA_DIR}/drivers/builtin/src
        ${TFPSA_DIR}/drivers/p256-m
        ${TFPSA_DIR}/drivers/p256-m/p256-m
        ${TFPSA_DIR}/drivers/pqcp/src
        ${TFPSA_DIR}/drivers/everest/include/tf-psa-crypto/private/everest
        ${TFPSA_DIR}/drivers/everest/include/tf-psa-crypto/private/everest/kremlib)

# Thread-safe: the crypto layer keeps global state (its random generator, its key store) and the
# engine reaches it from more than one thread (an HTTP client's worker, the game thread's wss).
# Mbed TLS: "You must enable this option if TF-PSA-Crypto runs in a multithreaded environment."
# pthreads where they exist (Linux, the Deck, the web, whose pthread mutexes are libc's); on
# Windows the alternate layer, whose types are mbedtls-house/threading_alt.h and whose functions
# mbedtlsc_start installs.
target_compile_definitions(mbedtls-c PRIVATE MBEDTLS_THREADING_C)
if(WIN32)
    target_compile_definitions(mbedtls-c PRIVATE MBEDTLS_THREADING_ALT)
    target_include_directories(mbedtls-c PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../mbedtls-house)
else()
    target_compile_definitions(mbedtls-c PRIVATE MBEDTLS_THREADING_PTHREAD)
endif()

# Position independent, since a consumer may end up in a shared object.
set_target_properties(mbedtls-c PROPERTIES POSITION_INDEPENDENT_CODE ON
                                           OUTPUT_NAME mbedtls-c)
