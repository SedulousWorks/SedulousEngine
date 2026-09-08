// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// VG conic (angular/sweep) gradient fragment shader. The tessellator emits (pos-center) rotated by
// -startAngle as TexCoord, so the parameter t = frac(atan2(y,x)/2pi) is computed PER PIXEL (exact
// angular sweep) instead of Gouraud-interpolating it. t is sampled from the baked 256x1 ramp LUT at
// texel centers. Outputs PREMULTIPLIED-alpha color to pair with the PremultipliedAlpha blend.
// Resolved via ShaderSystem::GetVariant("vg_grad_conic", Fragment).
struct PSInput { float4 Position:SV_Position; float2 TexCoord:TEXCOORD0; float4 Color:COLOR0; float Coverage:COVERAGE; };
Texture2D VGTexture : register(t0);
SamplerState VGSampler : register(s0);
float4 main(PSInput input) : SV_Target {
    const float kInvTwoPi = 0.15915494309; // 1/(2pi)
    float a = atan2(input.TexCoord.y, input.TexCoord.x) * kInvTwoPi; // (-0.5, 0.5]
    float t = a - floor(a);                                          // [0, 1), 0 at +x axis
    float u = (0.5 + t * 255.0) / 256.0; // texel center: pads + dodges the Repeat wrap seam
    float4 ramp = VGTexture.Sample(VGSampler, float2(u, 0.5));
    float4 result = ramp * input.Color;
    result.a *= input.Coverage;
    result.rgb *= result.a; // premultiply
    return result;
}
