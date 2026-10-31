// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// ImGui vertex shader: pos2D + uv + RGBA8 vertex color -> clip space via an ortho projection
// (row-vector mul, engine convention). Cooked into the engine shader pack like every other shader
// (WGSL for web); the ImGui renderer resolves it via ShaderSystem::GetVariant("imgui", Vertex).
cbuffer Proj : register(b0, space0) { row_major float4x4 Projection; };
struct VSIn  { float2 pos : TEXCOORD0; float2 uv : TEXCOORD1; float4 col : TEXCOORD2; };
struct VSOut { float4 pos : SV_Position; float2 uv : TEXCOORD0; float4 col : COLOR0; };
VSOut main(VSIn i) {
    VSOut o;
    o.pos = mul(float4(i.pos, 0.0, 1.0), Projection);
    o.uv  = i.uv;
    o.col = i.col;
    return o;
}
