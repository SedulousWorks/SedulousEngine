/* SPDX-License-Identifier: MIT
 * Copyright (c) 2026-Present Robert Campbell
 */
#include "mbedtls_c.h"

#include <mbedtls/build_info.h>
#include <mbedtls/version.h>
#include <mbedtls/threading.h>
#include <psa/crypto.h>
#include <mbedtls/error.h>
#include <mbedtls/md.h>
#include <mbedtls/pk.h>
#include <mbedtls/ssl.h>
#include <mbedtls/x509_crt.h>

#include <stdlib.h>
#include <string.h>

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

void mbedtlsc_strerror(int code, char* out, size_t size)
{
    if (out == NULL || size == 0)
        return;
    out[0] = 0;
    mbedtls_strerror(code, out, size);
}

/* ---- sessions ---------------------------------------------------------------------------- */

/* A growable byte buffer. */
typedef struct Bytes
{
    uint8_t* data;
    size_t size;
    size_t capacity;
} Bytes;

static int BytesAppend(Bytes* b, const uint8_t* bytes, size_t length)
{
    if (b->size + length > b->capacity)
    {
        size_t capacity = b->capacity < 256 ? 256 : b->capacity;
        while (capacity < b->size + length)
            capacity *= 2;
        uint8_t* grown = (uint8_t*)realloc(b->data, capacity);
        if (grown == NULL)
            return 0;
        b->data = grown;
        b->capacity = capacity;
    }
    if (length > 0)
        memcpy(b->data + b->size, bytes, length);
    b->size += length;
    return 1;
}

struct mbedtlsc_session
{
    mbedtls_ssl_config config;
    mbedtls_ssl_context ssl;
    mbedtls_x509_crt roots;
    mbedtls_x509_crt chain;
    mbedtls_pk_context key;
    /* Mbed TLS keeps the ALPN pointers: the names live as long as the session. */
    char** alpnNames;
    const char** alpn;
    int alpnCount;
    Bytes in;
    size_t inHead;
    Bytes out;
};

/* The memory BIO: what Mbed TLS sends goes to `out`; what it reads comes from `in`. */
static int SendToPeer(void* context, const unsigned char* bytes, size_t size)
{
    mbedtlsc_session* s = (mbedtlsc_session*)context;
    if (!BytesAppend(&s->out, bytes, size))
        return MBEDTLS_ERR_SSL_ALLOC_FAILED;
    return (int)size;
}

static int ReceiveFromPeer(void* context, unsigned char* bytes, size_t size)
{
    mbedtlsc_session* s = (mbedtlsc_session*)context;
    size_t available = s->in.size - s->inHead;
    size_t n;
    if (available == 0)
        return MBEDTLS_ERR_SSL_WANT_READ;
    n = available < size ? available : size;
    memcpy(bytes, s->in.data + s->inHead, n);
    s->inHead += n;
    if (s->inHead == s->in.size)
    {
        s->in.size = 0;
        s->inHead = 0;
    }
    return (int)n;
}

static mbedtls_ssl_protocol_version ToMbed(int version)
{
    return version == 3 ? MBEDTLS_SSL_VERSION_TLS1_3 : MBEDTLS_SSL_VERSION_TLS1_2;
}

mbedtlsc_session* mbedtlsc_session_create(int server, int minimum, int maximum, const char* const* alpn, int alpnCount,
                                          int* outCode)
{
    mbedtlsc_session* s = (mbedtlsc_session*)calloc(1, sizeof(mbedtlsc_session));
    int r;
    int i;
    *outCode = 0;
    if (s == NULL)
        return NULL;
    mbedtls_ssl_config_init(&s->config);
    mbedtls_ssl_init(&s->ssl);
    mbedtls_x509_crt_init(&s->roots);
    mbedtls_x509_crt_init(&s->chain);
    mbedtls_pk_init(&s->key);
    if (!mbedtlsc_start())
    {
        *outCode = MBEDTLSC_NOT_STARTED;
        return s;
    }
    r = mbedtls_ssl_config_defaults(&s->config, server ? MBEDTLS_SSL_IS_SERVER : MBEDTLS_SSL_IS_CLIENT,
                                    MBEDTLS_SSL_TRANSPORT_STREAM, MBEDTLS_SSL_PRESET_DEFAULT);
    if (r != 0)
    {
        *outCode = r;
        return s;
    }
    mbedtls_ssl_conf_min_tls_version(&s->config, ToMbed(minimum));
    mbedtls_ssl_conf_max_tls_version(&s->config, ToMbed(maximum));
    if (alpnCount > 0)
    {
        s->alpnNames = (char**)calloc((size_t)alpnCount, sizeof(char*));
        s->alpn = (const char**)calloc((size_t)alpnCount + 1, sizeof(char*));
        if (s->alpnNames == NULL || s->alpn == NULL)
        {
            *outCode = MBEDTLS_ERR_SSL_ALLOC_FAILED;
            return s;
        }
        s->alpnCount = alpnCount;
        for (i = 0; i < alpnCount; ++i)
        {
            size_t length = strlen(alpn[i]);
            s->alpnNames[i] = (char*)malloc(length + 1);
            if (s->alpnNames[i] == NULL)
            {
                *outCode = MBEDTLS_ERR_SSL_ALLOC_FAILED;
                return s;
            }
            memcpy(s->alpnNames[i], alpn[i], length + 1);
            s->alpn[i] = s->alpnNames[i];
        }
        s->alpn[alpnCount] = NULL;
        r = mbedtls_ssl_conf_alpn_protocols(&s->config, s->alpn);
        if (r != 0)
            *outCode = r;
    }
    return s;
}

void mbedtlsc_session_destroy(mbedtlsc_session* s)
{
    int i;
    if (s == NULL)
        return;
    mbedtls_ssl_free(&s->ssl);
    mbedtls_ssl_config_free(&s->config);
    mbedtls_x509_crt_free(&s->roots);
    mbedtls_x509_crt_free(&s->chain);
    mbedtls_pk_free(&s->key);
    if (s->alpnNames != NULL)
    {
        for (i = 0; i < s->alpnCount; ++i)
            free(s->alpnNames[i]);
    }
    free(s->alpnNames);
    free((void*)s->alpn);
    free(s->in.data);
    free(s->out.data);
    free(s);
}

/* A NUL-terminated copy: Mbed TLS's PEM parsers take the terminator in their length. */
static unsigned char* Terminated(const uint8_t* text, size_t length)
{
    unsigned char* copy = (unsigned char*)malloc(length + 1);
    if (copy == NULL)
        return NULL;
    if (length > 0)
        memcpy(copy, text, length);
    copy[length] = 0;
    return copy;
}

void mbedtlsc_session_add_roots_pem(mbedtlsc_session* s, const uint8_t* pem, size_t length)
{
    unsigned char* copy = Terminated(pem, length);
    if (copy == NULL)
        return;
    (void)mbedtls_x509_crt_parse(&s->roots, copy, length + 1);
    free(copy);
}

void mbedtlsc_session_add_root_der(mbedtlsc_session* s, const uint8_t* der, size_t length)
{
    (void)mbedtls_x509_crt_parse_der(&s->roots, der, length);
}

int mbedtlsc_session_root_count(mbedtlsc_session* s)
{
    int count = 0;
    const mbedtls_x509_crt* c;
    for (c = &s->roots; c != NULL && c->raw.len > 0; c = c->next)
        ++count;
    return count;
}

void mbedtlsc_session_verify(mbedtlsc_session* s, int verify)
{
    if (!verify)
    {
        mbedtls_ssl_conf_authmode(&s->config, MBEDTLS_SSL_VERIFY_NONE);
        return;
    }
    mbedtls_ssl_conf_authmode(&s->config, MBEDTLS_SSL_VERIFY_REQUIRED);
    mbedtls_ssl_conf_ca_chain(&s->config, &s->roots, NULL);
}

int mbedtlsc_session_own_certificate(mbedtlsc_session* s, const uint8_t* chainPem, size_t chainLength,
                                     const uint8_t* keyPem, size_t keyLength, int* outStage)
{
    unsigned char* chain = Terminated(chainPem, chainLength);
    unsigned char* key = Terminated(keyPem, keyLength);
    int r = MBEDTLS_ERR_SSL_ALLOC_FAILED;
    *outStage = 0;
    if (chain != NULL && key != NULL)
    {
        r = mbedtls_x509_crt_parse(&s->chain, chain, chainLength + 1);
        if (r == 0)
        {
            *outStage = 1;
            r = mbedtls_pk_parse_key(&s->key, key, keyLength + 1, NULL, 0);
        }
        if (r == 0)
        {
            *outStage = 2;
            r = mbedtls_ssl_conf_own_cert(&s->config, &s->chain, &s->key);
        }
    }
    free(chain);
    free(key);
    return r;
}

int mbedtlsc_session_setup(mbedtlsc_session* s)
{
    int r = mbedtls_ssl_setup(&s->ssl, &s->config);
    if (r != 0)
        return r;
    mbedtls_ssl_set_bio(&s->ssl, s, &SendToPeer, &ReceiveFromPeer, NULL);
    return 0;
}

int mbedtlsc_session_set_hostname(mbedtlsc_session* s, const char* name)
{
    return mbedtls_ssl_set_hostname(&s->ssl, name);
}

void mbedtlsc_session_receive(mbedtlsc_session* s, const uint8_t* bytes, size_t length)
{
    (void)BytesAppend(&s->in, bytes, length);
}

size_t mbedtlsc_session_outgoing(mbedtlsc_session* s) { return s->out.size; }

size_t mbedtlsc_session_take_outgoing(mbedtlsc_session* s, uint8_t* out, size_t capacity)
{
    size_t n = s->out.size < capacity ? s->out.size : capacity;
    if (n == 0)
        return 0;
    memcpy(out, s->out.data, n);
    memmove(s->out.data, s->out.data + n, s->out.size - n);
    s->out.size -= n;
    return n;
}

int mbedtlsc_session_handshake(mbedtlsc_session* s)
{
    int r = mbedtls_ssl_handshake(&s->ssl);
    if (r == 0)
        return MBEDTLSC_HANDSHAKE_DONE;
    if (r == MBEDTLS_ERR_SSL_WANT_READ || r == MBEDTLS_ERR_SSL_WANT_WRITE)
        return MBEDTLSC_HANDSHAKE_WANTS;
    if (r == MBEDTLS_ERR_X509_CERT_VERIFY_FAILED)
        return MBEDTLSC_HANDSHAKE_REFUSED;
    return r;
}

void mbedtlsc_session_verify_info(mbedtlsc_session* s, char* out, size_t size)
{
    if (out == NULL || size == 0)
        return;
    out[0] = 0;
    (void)mbedtls_x509_crt_verify_info(out, size, "", mbedtls_ssl_get_verify_result(&s->ssl));
}

int mbedtlsc_session_read(mbedtlsc_session* s, uint8_t* out, size_t capacity, int* outCode)
{
    unsigned round;
    *outCode = MBEDTLSC_READ_NONE;
    if (capacity == 0)
        return 0;
    for (round = 0;; ++round)
    {
        size_t before = s->in.size - s->inHead;
        int r = mbedtls_ssl_read(&s->ssl, out, capacity);
        if (r > 0)
            return r;
        if (r == MBEDTLS_ERR_SSL_WANT_READ || r == MBEDTLS_ERR_SSL_WANT_WRITE)
        {
            /* After a post-handshake message (TLS 1.3's tickets) Mbed TLS answers WANT_READ with
             * records still unread, here or in its own buffer; read on while some are, or data
             * that arrived with the peer's close would be lost. (Bounded: each round consumes a
             * record.) */
            size_t after = s->in.size - s->inHead;
            int unread = (after > 0 && after < before) || mbedtls_ssl_check_pending(&s->ssl) != 0;
            if (r == MBEDTLS_ERR_SSL_WANT_READ && unread && round < 64)
                continue;
            return 0;
        }
        if (r == MBEDTLS_ERR_SSL_RECEIVED_NEW_SESSION_TICKET)
            continue; /* TLS 1.3's after-handshake ticket: read on */
        if (r == 0 || r == MBEDTLS_ERR_SSL_PEER_CLOSE_NOTIFY)
        {
            *outCode = MBEDTLSC_READ_CLOSED;
            return 0;
        }
        *outCode = r;
        return 0;
    }
}

int mbedtlsc_session_write(mbedtlsc_session* s, const uint8_t* bytes, size_t length)
{
    size_t sent = 0;
    while (sent < length)
    {
        int r = mbedtls_ssl_write(&s->ssl, bytes + sent, length - sent);
        if (r < 0)
            return r;
        sent += (size_t)r;
    }
    return 0;
}

int mbedtlsc_session_close_notify(mbedtlsc_session* s) { return mbedtls_ssl_close_notify(&s->ssl); }

const char* mbedtlsc_session_alpn(mbedtlsc_session* s) { return mbedtls_ssl_get_alpn_protocol(&s->ssl); }

int mbedtlsc_session_version(mbedtlsc_session* s)
{
    return mbedtls_ssl_get_version_number(&s->ssl) == MBEDTLS_SSL_VERSION_TLS1_3 ? 3 : 2;
}

/* ---- certificates ------------------------------------------------------------------------ */

int mbedtlsc_self_signed_certificate(const char* name, const char* notBefore, const char* notAfter, char* certificatePem,
                                     size_t certificateSize, char* keyPem, size_t keySize, int* outStage)
{
    psa_key_attributes_t attributes = PSA_KEY_ATTRIBUTES_INIT;
    mbedtls_svc_key_id_t id = MBEDTLS_SVC_KEY_ID_INIT;
    mbedtls_pk_context key;
    mbedtls_x509write_cert writer;
    mbedtls_x509_san_list san;
    unsigned char serial[16];
    char* subject;
    size_t nameLength = strlen(name);
    int r;

    *outStage = 0;
    if (!mbedtlsc_start())
        return MBEDTLSC_NOT_STARTED;

    /* A new P-256 key, made in PSA and copied out for the writer. */
    *outStage = 1;
    psa_set_key_usage_flags(&attributes, PSA_KEY_USAGE_SIGN_HASH | PSA_KEY_USAGE_SIGN_MESSAGE | PSA_KEY_USAGE_EXPORT);
    psa_set_key_algorithm(&attributes, PSA_ALG_ECDSA(PSA_ALG_SHA_256));
    psa_set_key_type(&attributes, PSA_KEY_TYPE_ECC_KEY_PAIR(PSA_ECC_FAMILY_SECP_R1));
    psa_set_key_bits(&attributes, 256);
    if (psa_generate_key(&attributes, &id) != PSA_SUCCESS)
        return MBEDTLSC_NOT_STARTED;
    *outStage = 2;
    mbedtls_pk_init(&key);
    r = mbedtls_pk_copy_from_psa(id, &key);
    (void)psa_destroy_key(id);
    if (r != 0)
    {
        mbedtls_pk_free(&key);
        return r;
    }

    *outStage = 3;
    subject = (char*)malloc(nameLength + 4);
    if (subject == NULL)
    {
        mbedtls_pk_free(&key);
        return MBEDTLS_ERR_X509_ALLOC_FAILED;
    }
    memcpy(subject, "CN=", 3);
    memcpy(subject + 3, name, nameLength + 1);
    mbedtls_x509write_crt_init(&writer);
    mbedtls_x509write_crt_set_version(&writer, MBEDTLS_X509_CRT_VERSION_3);
    mbedtls_x509write_crt_set_md_alg(&writer, MBEDTLS_MD_SHA256);
    mbedtls_x509write_crt_set_subject_key(&writer, &key);
    mbedtls_x509write_crt_set_issuer_key(&writer, &key);
    (void)psa_generate_random(serial, sizeof(serial));
    serial[0] = (unsigned char)((serial[0] & 0x7F) | 0x01); /* positive, never zero */
    memset(&san, 0, sizeof(san));
    san.node.type = MBEDTLS_X509_SAN_DNS_NAME;
    san.node.san.unstructured_name.p = (unsigned char*)name;
    san.node.san.unstructured_name.len = nameLength;
    san.next = NULL;
    r = mbedtls_x509write_crt_set_subject_name(&writer, subject);
    if (r == 0)
        r = mbedtls_x509write_crt_set_issuer_name(&writer, subject);
    if (r == 0)
        r = mbedtls_x509write_crt_set_serial_raw(&writer, serial, sizeof(serial));
    if (r == 0)
        r = mbedtls_x509write_crt_set_validity(&writer, notBefore, notAfter);
    if (r == 0)
        r = mbedtls_x509write_crt_set_subject_alternative_name(&writer, &san);
    if (r == 0)
        r = mbedtls_x509write_crt_set_key_usage(&writer, MBEDTLS_X509_KU_DIGITAL_SIGNATURE);
    if (r == 0)
        r = mbedtls_x509write_crt_pem(&writer, (unsigned char*)certificatePem, certificateSize);
    mbedtls_x509write_crt_free(&writer);
    free(subject);
    if (r != 0)
    {
        mbedtls_pk_free(&key);
        return r;
    }

    *outStage = 4;
    r = mbedtls_pk_write_key_pem(&key, (unsigned char*)keyPem, keySize);
    mbedtls_pk_free(&key);
    return r;
}
