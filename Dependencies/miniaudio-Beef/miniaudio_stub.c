/*
 * The ONE translation unit that compiles miniaudio itself, plus stb_vorbis so miniaudio
 * picks up its built in Ogg backend (it does that automatically when the header only part
 * is visible before the implementation). Kept apart from the shim so the vendored code is
 * compiled exactly once and nothing else in the build sees its internals.
 */
#if defined(__GNUC__)
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wunused-variable"
#pragma GCC diagnostic ignored "-Wunused-but-set-variable"
#pragma GCC diagnostic ignored "-Wsign-compare"
#endif
#if defined(__GNUC__) && !defined(__clang__)
#pragma GCC diagnostic ignored "-Wmaybe-uninitialized"
#endif
#if defined(__clang__)
#pragma clang diagnostic ignored "-Wunused-but-set-variable"
#pragma clang diagnostic ignored "-Wshift-op-parentheses"
#pragma clang diagnostic ignored "-Wtautological-compare"
#endif

#define STB_VORBIS_HEADER_ONLY
#include "stb_vorbis.c" /* header only pass: enables miniaudio's built in Ogg backend */

#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio/miniaudio.h"

#undef STB_VORBIS_HEADER_ONLY
#include "stb_vorbis.c" /* implementation pass */
