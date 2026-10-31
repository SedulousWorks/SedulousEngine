// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// VG (2D vector-graphics) fragment shader. Samples the atlas at t0/s0, modulates by the vertex
// color, folds AA coverage into alpha, and outputs PREMULTIPLIED-alpha color (rgb *= a) to pair
// with the renderer's PremultipliedAlpha blend. Premultiplied compositing removes the dark halo on
// straight-alpha AA edges and the double-blend seams where fringe/joins share edges (NanoVG's
// approach). Resolved via ShaderSystem::GetVariant("vg", Fragment).
#include "color.hlsli"
cbuffer VGUniforms : register(b0) { float4x4 Projection; float DistanceFieldPixelRange; float DistanceFieldAtlasWidth; float DistanceFieldAtlasHeight; float BlendSpace; };
struct PSInput { float4 Position:SV_Position; float2 TexCoord:TEXCOORD0; float4 Color:COLOR0; float Coverage:COVERAGE; };
Texture2D VGTexture : register(t0);
SamplerState VGSampler : register(s0);
float4 main(PSInput input) : SV_Target {
    float4 texColor = VGTexture.Sample(VGSampler, input.TexCoord);
    // Sampled colour arrives in linear light (an sRGB texture decoded, or a linear one); an
    // Encoded canvas works on encoded values, so it is encoded back (white coverage stays 1).
    if (BlendSpace > 0.5) { texColor.rgb = LinearToSrgb(texColor.rgb); }
    float4 result = texColor * input.Color;
    result.a *= input.Coverage;
    result.rgb *= result.a; // premultiply
    return result;
}
