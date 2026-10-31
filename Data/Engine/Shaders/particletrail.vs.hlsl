// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#pragma pack_matrix(row_major)
cbuffer ParticleView : register(b0, space0) {
    float4x4 ViewProj;
    float4x4 View;
    float    ProjZScale;    // Proj[2][2] (soft particles, the billboard pixel stage)
    float    ProjZOffset;   // Proj[3][2]
    float    ProjWScale;    // Proj[2][3]
    float    _particleViewPad0;
};
struct VSIn { float3 Position : TEXCOORD0; float2 UV : TEXCOORD1; float4 Color : TEXCOORD2; };
struct VSOut { float4 pos : SV_Position; float2 uv : TEXCOORD0; float4 col : COLOR0; };
VSOut main(VSIn i) { VSOut o; o.pos = mul(float4(i.Position, 1.0), ViewProj); o.uv = i.UV; o.col = i.Color; return o; }
