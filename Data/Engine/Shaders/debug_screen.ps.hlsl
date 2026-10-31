// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

Texture2D    FontAtlas : register(t0, space0);
SamplerState FontSamp  : register(s0, space0);
float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0, float4 col : TEXCOORD1) : SV_Target {
    float a = FontAtlas.SampleLevel(FontSamp, uv, 0).r;
    return float4(col.rgb, col.a * a);
}
