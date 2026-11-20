// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// A masked caster's cut-out: the material's albedo alpha against the threshold the renderer pushes
// (GpuCutoutPush: AlphaCutoff over the base colour's alpha), so the shadow has the holes the
// forward draw has.
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
void main(float4 pos : SV_Position, float2 uv : TEXCOORD0) {
    if (AlbedoMap.Sample(MainSampler, uv).a < cutout.AlphaThreshold) { discard; }
}
