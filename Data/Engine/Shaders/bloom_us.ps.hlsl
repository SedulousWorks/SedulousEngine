// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "bloom_common.hlsli"

float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    float2 t = pc.SrcTexel;
    float3 s = Src.SampleLevel(Samp, uv + t * float2(-1,-1), 0).rgb * 1.0
             + Src.SampleLevel(Samp, uv + t * float2( 0,-1), 0).rgb * 2.0
             + Src.SampleLevel(Samp, uv + t * float2( 1,-1), 0).rgb * 1.0
             + Src.SampleLevel(Samp, uv + t * float2(-1, 0), 0).rgb * 2.0
             + Src.SampleLevel(Samp, uv,                     0).rgb * 4.0
             + Src.SampleLevel(Samp, uv + t * float2( 1, 0), 0).rgb * 2.0
             + Src.SampleLevel(Samp, uv + t * float2(-1, 1), 0).rgb * 1.0
             + Src.SampleLevel(Samp, uv + t * float2( 0, 1), 0).rgb * 2.0
             + Src.SampleLevel(Samp, uv + t * float2( 1, 1), 0).rgb * 1.0;
    return float4(s * (1.0 / 16.0), 1.0);
}
