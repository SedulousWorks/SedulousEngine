// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// ImGui pixel shader: vertex color * font-atlas sample. Resolved via
// ShaderSystem::GetVariant("imgui", Fragment).
Texture2D    FontTex  : register(t0, space0);
SamplerState FontSamp : register(s0, space0);
struct PSIn { float4 pos : SV_Position; float2 uv : TEXCOORD0; float4 col : COLOR0; };
float4 main(PSIn i) : SV_Target { return i.col * FontTex.Sample(FontSamp, i.uv); }
