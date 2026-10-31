/* SPDX-License-Identifier: MIT
 * Copyright (c) 2026-Present Robert Campbell
 */
#include "mbedtls_c.h"

#include <mbedtls/build_info.h>
#include <mbedtls/version.h>
#include <mbedtls/threading.h>
#include <psa/crypto.h>

#if defined(MBEDTLS_THREADING_ALT)
/* Windows: Mbed TLS's alternate threading layer (no pthreads), over Win32's slim lock and
 * condition variable (the types: mbedtls-house/threading_alt.h). */
static int MutexInit(mbedtls_platform_mutex_t* m)
{
    InitializeSRWLock(m);
    return 0;
}
static void MutexDestroy(mbedtls_platform_mutex_t* m) { (void)m; }
static int MutexLock(mbedtls_platform_mutex_t* m)
{
    AcquireSRWLockExclusive(m);
    return 0;
}
static int MutexUnlock(mbedtls_platform_mutex_t* m)
{
    ReleaseSRWLockExclusive(m);
    return 0;
}
static int CondInit(mbedtls_platform_condition_variable_t* c)
{
    InitializeConditionVariable(c);
    return 0;
}
static void CondDestroy(mbedtls_platform_condition_variable_t* c) { (void)c; }
static int CondSignal(mbedtls_platform_condition_variable_t* c)
{
    WakeConditionVariable(c);
    return 0;
}
static int CondBroadcast(mbedtls_platform_condition_variable_t* c)
{
    WakeAllConditionVariable(c);
    return 0;
}
static int CondWait(mbedtls_platform_condition_variable_t* c, mbedtls_platform_mutex_t* m)
{
    return SleepConditionVariableSRW(c, m, INFINITE, 0) ? 0 : MBEDTLS_ERR_THREADING_USAGE_ERROR;
}

static INIT_ONCE sStartOnce = INIT_ONCE_STATIC_INIT;
static int sStarted = 0;

static BOOL CALLBACK StartOnce(PINIT_ONCE once, PVOID parameter, PVOID* context)
{
    (void)once;
    (void)parameter;
    (void)context;
    mbedtls_threading_set_alt(&MutexInit, &MutexDestroy, &MutexLock, &MutexUnlock, &CondInit, &CondDestroy,
                              &CondSignal, &CondBroadcast, &CondWait);
    sStarted = psa_crypto_init() == PSA_SUCCESS;
    return TRUE;
}

int mbedtlsc_start(void)
{
    InitOnceExecuteOnce(&sStartOnce, &StartOnce, NULL, NULL);
    return sStarted;
}
#else
#include <pthread.h>

static pthread_once_t sStartOnce = PTHREAD_ONCE_INIT;
static int sStarted = 0;

static void StartOnce(void) { sStarted = psa_crypto_init() == PSA_SUCCESS; }

int mbedtlsc_start(void)
{
    pthread_once(&sStartOnce, &StartOnce);
    return sStarted;
}
#endif

const char* mbedtlsc_version(void) { return mbedtls_version_get_string(); }

int mbedtlsc_sha256(const uint8_t* data, size_t length, uint8_t* out)
{
    size_t written = 0;
    if (!mbedtlsc_start())
        return 0;
    return psa_hash_compute(PSA_ALG_SHA_256, data, length, out, 32, &written) == PSA_SUCCESS && written == 32;
}
