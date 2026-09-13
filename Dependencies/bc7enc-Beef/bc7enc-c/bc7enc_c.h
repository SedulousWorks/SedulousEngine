// SPDX-License-Identifier: MIT
// A flat C surface over bc7enc's BC1-BC7 encoders and decoders.
//
// bc7enc.h declares C functions but hands them a struct with member functions; rgbcx and
// bc7decomp are C++ namespaces with defaulted arguments. None of that crosses a C ABI, so
// everything a caller needs is re-declared here with plain arguments and no defaults.

#ifndef BC7ENC_C_H
#define BC7ENC_C_H

#include <stdint.h>

#if defined(__cplusplus)
extern "C" {
#endif

/// One-time global table init for BOTH encoders. Idempotent, and every encode call below
/// requires it. BC1 uses the ideal approximation rather than a vendor-specific one.
void bc7encc_init(void);

/// The highest level rgbcx's BC1 and BC3 encoders accept, for a caller mapping its own
/// quality scale onto them.
uint32_t bc7encc_rgbcx_max_level(void);

// ---- encode: one 4x4 block of tightly packed RGBA8 (64 bytes) ----------------------------

/// 8 bytes out. Alpha is ignored.
void bc7encc_encode_bc1(uint32_t level, void* dst, const uint8_t* pixels, int allowThreeColor,
                        int useTransparentTexelsForBlack);
/// 16 bytes out: BC1 colour plus a BC4 alpha block.
void bc7encc_encode_bc3(uint32_t level, void* dst, const uint8_t* pixels);
/// 8 bytes out, from one channel selected by `stride`'s starting offset convention.
void bc7encc_encode_bc4(void* dst, const uint8_t* pixels, uint32_t stride);
/// 16 bytes out, two channels.
void bc7encc_encode_bc5(void* dst, const uint8_t* pixels, uint32_t chan0, uint32_t chan1,
                        uint32_t stride);
/// 16 bytes out. `uberLevel` is 0..4, higher being slower and better.
void bc7encc_encode_bc7(void* dst, const uint8_t* pixels, uint32_t uberLevel);

// ---- decode: one block back to 64 bytes of RGBA8 -----------------------------------------

/// False when the block used the three colour mode, which is what the caller checks to know
/// whether the block carried transparency.
int bc7encc_unpack_bc1(const void* block, void* pixels, int setAlpha);
int bc7encc_unpack_bc3(const void* block, void* pixels);
void bc7encc_unpack_bc4(const void* block, uint8_t* pixels, uint32_t stride);
void bc7encc_unpack_bc5(const void* block, void* pixels, uint32_t chan0, uint32_t chan1,
                        uint32_t stride);
/// False on a reserved or invalid mode.
int bc7encc_unpack_bc7(const void* block, void* pixels);

#if defined(__cplusplus)
}
#endif

#endif // BC7ENC_C_H
