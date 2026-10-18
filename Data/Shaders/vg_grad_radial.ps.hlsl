// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// VG radial-gradient fragment shader. The tessellator emits the gradient-space coordinate
// (pos-center)/radius as TexCoord, so the parameter t = length(TexCoord) is computed PER PIXEL
// (exact radial falloff) instead of Gouraud-interpolating it across triangles. The RAW t samples
// the baked 256x1 ramp LUT and the bound SAMPLER's address mode applies the spread: clamp = pad,
// wrap = repeat, mirror = reflect (the renderer picks the sampler from the command's
// VGGradientSpread). Outputs PREMULTIPLIED-alpha color to pair with the PremultipliedAlpha blend.
// Resolved via ShaderSystem::GetVariant("vg_grad_radial", Fragment).
#include "color.hlsli"
cbuffer VGUniforms : register(b0) { float4x4 Projection; float DistanceFieldPixelRange; float DistanceFieldAtlasWidth; float DistanceFieldAtlasHeight; float BlendSpace; };
struct PSInput { float4 Position:SV_Position; float2 TexCoord:TEXCOORD0; float4 Color:COLOR0; float Coverage:COVERAGE; };
Texture2D VGTexture : register(t0);
SamplerState VGSampler : register(s0);
float4 main(PSInput input) : SV_Target {
    float t = length(input.TexCoord);
    float4 ramp = VGTexture.Sample(VGSampler, float2(t, 0.5)); // sampler address mode = spread
    // Sampled colour arrives in linear light (an sRGB texture decoded, or a linear one); an
    // Encoded canvas works on encoded values, so it is encoded back (white coverage stays 1).
    if (BlendSpace > 0.5) { ramp.rgb = LinearToSrgb(ramp.rgb); }
    float4 result = ramp * input.Color;
    result.a *= input.Coverage;
    result.rgb *= result.a; // premultiply
    return result;
}
