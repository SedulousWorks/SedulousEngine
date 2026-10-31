// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// SSGI radiance prefilter: quarter-res box downsample of the lit HDR, the trace's gather
// source. THE structural firefly fix (Godot SSIL gathers from mip 5 of last frame's HDR):
// every radiance tap the trace takes is then already a ~16-pixel average, so a single
// blown-out texel is diluted 16:1 before any ray ever sees it - variance dies at the
// SOURCE instead of asking the denoisers to fix a spiked estimate after the fact.

#include "push_constant.hlsli"
Texture2D<float4> SceneTex  : register(t0, space0);
SamplerState      LinearSamp: register(s0, space0);

struct SsgiDownPush {
    float2 SrcTexelSize;   // 1 / SOURCE (full-res) size
    float2 _pad0;
};
PUSH_CONSTANT(SsgiDownPush, pc, space1);

float3 Tap(float2 uv) {
    float3 c = SceneTex.SampleLevel(LinearSamp, uv, 0).rgb;
    // Sanitize per tap (Godot sanitizes every pyramid level): one inf/NaN texel must
    // not poison the average - and NaN is unfixable everywhere downstream. No isnan:
    // naga cannot translate OpIsNan (WGSL removed isNan) - NaN fails c == c instead
    // (select = OpSelect, which naga handles), and clamp's min/max eat the infinities.
    return select(c == c, clamp(c, 0.0, 65504.0), float3(0.0, 0.0, 0.0));
}

// 4 bilinear taps on the 2x2-quad corners = a 4x4 box of the source per output texel.
float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    float2 st = pc.SrcTexelSize;
    float3 c = Tap(uv + float2(-1.0, -1.0) * st) + Tap(uv + float2(1.0, -1.0) * st) +
               Tap(uv + float2(-1.0, 1.0) * st) + Tap(uv + float2(1.0, 1.0) * st);
    return float4(c * 0.25, 1.0);
}
