// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "push_constant.hlsli"
struct VSIn  { float3 pos : TEXCOORD0; float2 uv : TEXCOORD1; float4 col : TEXCOORD2; };
struct VSOut { float4 pos : SV_Position; float2 uv : TEXCOORD0; float4 col : TEXCOORD1; };
struct ScreenPush { float2 InvSize; float2 _pad; };
PUSH_CONSTANT(ScreenPush, pc, space1);
VSOut main(VSIn i) {
    VSOut o;
    float2 ndc = float2(i.pos.x * pc.InvSize.x * 2.0 - 1.0, 1.0 - i.pos.y * pc.InvSize.y * 2.0);
    o.pos = float4(ndc, 0.0, 1.0);
    o.uv = i.uv; o.col = i.col;
    return o;
}
