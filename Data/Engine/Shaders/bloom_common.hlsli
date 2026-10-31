// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "push_constant.hlsli"
Texture2D<float4> Src  : register(t0, space0);
SamplerState      Samp : register(s0, space0);
struct BloomPush {
    float2 SrcTexel;   // 1 / source size (filter tap spacing)
    float  Threshold;  // brightness cutoff (first downsample only)
    float  Knee;       // soft-knee width
    int    FirstPass;  // 1 = threshold + firefly-average the source (mip 0)
    float  _pad0, _pad1, _pad2; // scalar pad: a vec3 needs 16-byte alignment in a WGSL uniform
};
PUSH_CONSTANT(BloomPush, pc, space1);
