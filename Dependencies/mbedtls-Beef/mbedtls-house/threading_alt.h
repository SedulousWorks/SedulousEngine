/* SPDX-License-Identifier: MIT
 * Copyright (c) 2026-Present Robert Campbell
 *
 * Mbed TLS's alternate threading types on Windows (MBEDTLS_THREADING_ALT; no pthreads there):
 * Win32's slim reader-writer lock and condition variable. The functions over them are installed
 * by the wrapper (mbedtls-c/mbedtls_c.c, mbedtlsc_start, through mbedtls_threading_set_alt) before
 * the crypto library starts. Linux, the Deck and the web use MBEDTLS_THREADING_PTHREAD instead.
 */
#ifndef HOUSE_MBEDTLS_THREADING_ALT_H
#define HOUSE_MBEDTLS_THREADING_ALT_H

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

typedef SRWLOCK mbedtls_platform_mutex_t;
typedef CONDITION_VARIABLE mbedtls_platform_condition_variable_t;

#endif
