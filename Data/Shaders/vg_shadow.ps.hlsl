// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// VG box-shadow fragment shader (the BoxShadow draw mode): a Gaussian-blurred rounded rectangle.
// The context emits four quadrant quads whose texcoord carries the rounded-box SDF operand
// q = |p - c| - (halfSize - r) in BLUR-SIGMA units (linear within a quadrant, so it interpolates
// exactly) and whose coverage carries the corner radius r / sigma (negative = INSET). The
// distance d = length(max(q, 0)) + min(max(q.x, q.y), 0) - r is the signed distance to the
// rounded box in sigma units; the shadow's alpha is the Gaussian integral across that edge,
// 1 - Phi(d), via an erf approximation (Abramowitz-Stegun 7.1.26, |error| < 1.5e-7). No texture.
// Shares VGUniforms (b0) with vg.vs. Resolved via ShaderSystem::GetVariant("vg_shadow", Fragment).
cbuffer VGUniforms : register(b0) { float4x4 Projection; float DistanceFieldPixelRange; float DistanceFieldAtlasWidth; float DistanceFieldAtlasHeight; float _pad; };
struct PSInput { float4 Position:SV_Position; float2 TexCoord:TEXCOORD0; float4 Color:COLOR0; float Coverage:COVERAGE; };
float Erf(float x) {
    float s = sign(x);
    float a = abs(x);
    float t = 1.0 / (1.0 + 0.3275911 * a);
    float y = 1.0 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * exp(-a * a);
    return s * y;
}
float4 main(PSInput input) : SV_Target {
    float r = abs(input.Coverage);
    float2 q = input.TexCoord;
    float d = length(max(q, float2(0.0, 0.0))) + min(max(q.x, q.y), 0.0) - r;
    // Inset: the shadow lives INSIDE the box, fading away from the edge, so the distance flips.
    if (input.Coverage < 0.0) { d = -d; }
    // 1 - Phi(d): the fraction of a unit-sigma Gaussian centred on the pixel that lies inside.
    float alpha = 0.5 - 0.5 * Erf(d * 0.70710678);
    float4 result = input.Color;
    result.a *= alpha;
    result.rgb *= result.a; // premultiplied output, pairs with the PremultipliedAlpha blend
    return result;
}
