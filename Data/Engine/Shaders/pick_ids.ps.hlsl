// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GPU picking PS: write the draw's entity id (index + 1, generation) into the RG32Uint id target.
// Masked materials keep their cutout (a hole in a leaf is not the leaf), sampling the material's
// albedo alpha from set 2 against the pushed threshold, as shadow_depth.ps does.
// variants: ALPHA_TEST
#ifdef ALPHA_TEST
#include "push_constant.hlsli"
struct CutoutPush {
    float AlphaThreshold;
    float _cutoutPad0;
    float _cutoutPad1;
    float _cutoutPad2;
};
PUSH_CONSTANT(CutoutPush, cutout, space3);
Texture2D    AlbedoMap   : register(t0, space2);
SamplerState MainSampler : register(s0, space2);
#endif
struct PickVSOut {
    float4 pos : SV_Position;
    nointerpolation uint2 id : TEXCOORD0;
#ifdef ALPHA_TEST
    float2 uv : TEXCOORD1;
#endif
};
uint2 main(PickVSOut input) : SV_Target0 {
#ifdef ALPHA_TEST
    if (AlbedoMap.Sample(MainSampler, input.uv).a < cutout.AlphaThreshold) { discard; }
#endif
    return input.id;
}
