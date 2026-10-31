// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// VG (2D vector-graphics) vertex shader. Transforms a 2D position by the projection cbuffer and
// passes texcoord / color / coverage / effect through. Shared by the standard and distance-field pipelines.
// Cooked into the engine shader pack like every other engine shader (WGSL for web, SPIR-V/DXIL for
// desktop) - the VG renderer/UI resolves it via ShaderSystem::GetVariant("vg", Vertex).
//
// Vertex colors are AUTHORED IN sRGB (byte colors from themes/styles) but the whole VG
// pipeline works in linear space on an sRGB target: textures and gradient LUTs are
// sRGB-decoded by the sampler, and the swapchain encodes on write. Decoding here (once
// per vertex, exact IEC transfer) makes solid fills/strokes/text display EXACTLY the
// authored bytes - matching the texture paths - and makes color interpolation across
// triangles happen in linear space. Alpha is coverage, not color: it stays linear.
// An Encoded canvas (BlendSpace 1, VGBlendSpace::Encoded) draws into a UNORM view of its target and
// blends encoded values, as browsers do: its colours stay as authored.
#pragma pack_matrix(row_major)
#include "color.hlsli"
cbuffer VGUniforms : register(b0) { float4x4 Projection; float DistanceFieldPixelRange; float DistanceFieldAtlasWidth; float DistanceFieldAtlasHeight; float BlendSpace; };
// Effect (a distance-field text effect pass, VGVertex::effect) is the last output, so the
// fragment shaders that do not read it declare a prefix of this signature.
struct VSInput { float2 Position:TEXCOORD0; float2 TexCoord:TEXCOORD1; float4 Color:TEXCOORD2; float Coverage:TEXCOORD3; float2 Effect:TEXCOORD4; };
struct VSOutput { float4 Position:SV_Position; float2 TexCoord:TEXCOORD0; float4 Color:COLOR0; float Coverage:COVERAGE; float2 Effect:EFFECT; };
VSOutput main(VSInput input) {
    VSOutput o;
    o.Position = mul(float4(input.Position, 0.0, 1.0), Projection);
    o.TexCoord = input.TexCoord;
    o.Color = float4(BlendSpace > 0.5 ? input.Color.rgb : SrgbToLinear(input.Color.rgb), input.Color.a);
    o.Coverage = input.Coverage;
    o.Effect = input.Effect;
    return o;
}
