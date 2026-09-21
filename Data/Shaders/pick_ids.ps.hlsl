// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GPU picking PS: write the draw's entity id (index + 1, generation) into the RG32Uint id target.
// Masked materials keep their cutout (a hole in a leaf is not the leaf), sampling the material's
// albedo alpha from set 2 exactly like shadow_depth.ps.
// variants: ALPHA_TEST
#ifdef ALPHA_TEST
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
    if (AlbedoMap.Sample(MainSampler, input.uv).a < 0.5) { discard; }
#endif
    return input.id;
}
