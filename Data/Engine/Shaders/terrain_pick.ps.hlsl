// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell
// variants: HOLES

// Terrain GPU-pick PS: the terrain entity's id into the RG32Uint id target (see pick_ids.ps).
// Under HOLES a fragment inside a cut (the bilinear hole mask above one half) is discarded, so
// a click through a hole picks what lies below rather than the missing surface.
struct PickVSOut {
    float4 pos : SV_Position;
    nointerpolation uint2 id : TEXCOORD0;
#ifdef HOLES
    float2 splatUV : TEXCOORD6;
#endif
};
#ifdef HOLES
Texture2D    HoleMask    : register(t1, space2);
SamplerState HoleSampler : register(s0, space2);
#endif

uint2 main(PickVSOut input) : SV_Target0 {
#ifdef HOLES
    float2 dims;
    HoleMask.GetDimensions(dims.x, dims.y);
    if (HoleMask.Sample(HoleSampler, input.splatUV + 0.5 / max(dims, float2(1.0, 1.0))).r > 0.5) { discard; }
#endif
    return input.id;
}
