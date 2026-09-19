// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "push_constant.hlsli"
#include "depth.hlsli"
struct VSIn  { float3 pos : TEXCOORD0; float4 col : TEXCOORD1; };
struct VSOut { float4 pos : SV_Position; float4 col : TEXCOORD0; };
struct GeomPush { row_major float4x4 ViewProj; };
PUSH_CONSTANT(GeomPush, pc, space0);
static const float kDepthBias = 0.0005;
VSOut main(VSIn i) {
    VSOut o;
    o.pos = mul(float4(i.pos, 1.0), pc.ViewProj);
    o.pos = BiasClipTowardViewer(o.pos, kDepthBias);   // pull toward the camera to beat TAA-jitter depth noise
    o.col = i.col;
    return o;
}
