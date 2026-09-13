// SPDX-License-Identifier: MIT
#include "bc7enc_c.h"

#include "bc7decomp.h"
#include "bc7enc.h"
#include "rgbcx.h"

namespace
{
    // The table init runs once however many times a caller asks for it, which is what lets the
    // Beef side call it from every entry point rather than tracking the state itself.
    bool gInitialised = false;
}

extern "C" void bc7encc_init(void)
{
    if (gInitialised)
    {
        return;
    }
    gInitialised = true;
    bc7enc_compress_block_init();
    rgbcx::init(rgbcx::bc1_approx_mode::cBC1Ideal);
}

extern "C" uint32_t bc7encc_rgbcx_max_level(void)
{
    return rgbcx::MAX_LEVEL;
}

extern "C" void bc7encc_encode_bc1(uint32_t level, void* dst, const uint8_t* pixels,
                                   int allowThreeColor, int useTransparentTexelsForBlack)
{
    rgbcx::encode_bc1(level, dst, pixels, allowThreeColor != 0,
                      useTransparentTexelsForBlack != 0);
}

extern "C" void bc7encc_encode_bc3(uint32_t level, void* dst, const uint8_t* pixels)
{
    rgbcx::encode_bc3(level, dst, pixels);
}

extern "C" void bc7encc_encode_bc4(void* dst, const uint8_t* pixels, uint32_t stride)
{
    rgbcx::encode_bc4(dst, pixels, stride);
}

extern "C" void bc7encc_encode_bc5(void* dst, const uint8_t* pixels, uint32_t chan0,
                                   uint32_t chan1, uint32_t stride)
{
    rgbcx::encode_bc5(dst, pixels, chan0, chan1, stride);
}

extern "C" void bc7encc_encode_bc7(void* dst, const uint8_t* pixels, uint32_t uberLevel)
{
    bc7enc_compress_block_params params;
    bc7enc_compress_block_params_init(&params);
    params.m_uber_level = uberLevel;
    bc7enc_compress_block(dst, pixels, &params);
}

extern "C" int bc7encc_unpack_bc1(const void* block, void* pixels, int setAlpha)
{
    return rgbcx::unpack_bc1(block, pixels, setAlpha != 0, rgbcx::bc1_approx_mode::cBC1Ideal)
               ? 1
               : 0;
}

extern "C" int bc7encc_unpack_bc3(const void* block, void* pixels)
{
    return rgbcx::unpack_bc3(block, pixels, rgbcx::bc1_approx_mode::cBC1Ideal) ? 1 : 0;
}

extern "C" void bc7encc_unpack_bc4(const void* block, uint8_t* pixels, uint32_t stride)
{
    rgbcx::unpack_bc4(block, pixels, stride);
}

extern "C" void bc7encc_unpack_bc5(const void* block, void* pixels, uint32_t chan0,
                                   uint32_t chan1, uint32_t stride)
{
    rgbcx::unpack_bc5(block, pixels, chan0, chan1, stride);
}

extern "C" int bc7encc_unpack_bc7(const void* block, void* pixels)
{
    return bc7decomp::unpack_bc7(block, static_cast<bc7decomp::color_rgba*>(pixels)) ? 1 : 0;
}
