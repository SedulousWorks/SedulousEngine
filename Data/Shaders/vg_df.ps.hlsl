// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// VG distance-field (MSDF) text fragment shader. Decodes a median-of-3 signed distance from the
// atlas and antialiases in SCREEN space (pxRange scaled by fwidth of the texcoord), so text stays
// crisp at any scale. Shares VGUniforms (b0) for the DF metadata; pairs with vg.vs. Resolved via
// ShaderSystem::GetVariant("vg_df", Fragment). fwidth is called unconditionally (uniformity-safe
// for the WGSL/naga+tint cook).
cbuffer VGUniforms : register(b0) { float4x4 Projection; float DistanceFieldPixelRange; float DistanceFieldAtlasWidth; float DistanceFieldAtlasHeight; float _pad; };
struct PSInput { float4 Position:SV_Position; float2 TexCoord:TEXCOORD0; float4 Color:COLOR0; float Coverage:COVERAGE; };
Texture2D VGTexture : register(t0);
SamplerState VGSampler : register(s0);
float Median(float r, float g, float b) { return max(min(r, g), min(max(r, g), b)); }
float4 main(PSInput input) : SV_Target {
    float3 msd = VGTexture.Sample(VGSampler, input.TexCoord).rgb;
    float sd = Median(msd.r, msd.g, msd.b);
    // Screen-space px range: convert the atlas-space DF spread to screen pixels via the texcoord
    // derivatives, so the antialiased edge is ~1px wide regardless of magnification.
    float2 unitRange = float2(DistanceFieldPixelRange, DistanceFieldPixelRange) / float2(DistanceFieldAtlasWidth, DistanceFieldAtlasHeight);
    float2 screenTexSize = float2(1.0, 1.0) / max(fwidth(input.TexCoord), float2(1e-6, 1e-6));
    float screenPxRange = max(0.5 * dot(unitRange, screenTexSize), 1.0);
    float opacity = clamp(screenPxRange * (sd - 0.5) + 0.5, 0.0, 1.0);
    float4 result = input.Color;
    result.a *= opacity * input.Coverage;
    result.rgb *= result.a; // premultiplied output, pairs with the PremultipliedAlpha blend
    return result;
}
