// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "push_constant.hlsli"
Texture2D<float4> HdrTex    : register(t0, space0);
Texture2D<float4> AoTex     : register(t1, space0);
SamplerState      PointSamp : register(s0, space0);
struct ApplyPush { float Strength; float FlipAoY; float _pad1, _pad2; }; // scalar pad: vec3 needs 16-align in a WGSL uniform
PUSH_CONSTANT(ApplyPush, pc, space1);
float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    float3 c  = HdrTex.SampleLevel(PointSamp, uv, 0).rgb;
    // AO buffer is stored Y-flipped vs the scene on Y-flip targets (WebGPU today); realign via FlipAoY.
    float2 aoUv = float2(uv.x, pc.FlipAoY > 0.5 ? 1.0 - uv.y : uv.y);
    float  ao = lerp(1.0, AoTex.SampleLevel(PointSamp, aoUv, 0).r, saturate(pc.Strength));
    return float4(c * ao, 1.0);
}
