// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// VG layer blur fragment shader: one axis of a separable Gaussian over a layer's target (its
// premultiplied colour, in the canvas's own blend space, so a blur of an Encoded canvas blends
// encoded values as browsers do). The renderer runs it across, then down. Taps outside the
// content region count as transparent (the target beyond it holds stale texels); the layer's
// bounds carry three sigmas of margin, so its edges are transparent already. Resolved via
// ShaderSystem::GetVariant("vg_blur", Fragment).
cbuffer VGBlur : register(b0) {
    float2 Step;   // one texel along this pass's axis, in texture coordinates
    float2 Region; // the content's extent in texture coordinates (the target may be larger)
    float Sigma;   // in pixels
    float Radius;  // taps each side, ceil(3 sigma)
    float2 Unused;
};
struct PSInput { float4 Position : SV_Position; float2 TexCoord : TEXCOORD0; };
Texture2D Source : register(t0);
SamplerState SourceSampler : register(s0);
float4 main(PSInput input) : SV_Target {
    const float2 uv = input.TexCoord * Region;
    const int radius = (int)Radius;
    const float falloff = -0.5 / (Sigma * Sigma);
    float4 sum = float4(0.0, 0.0, 0.0, 0.0);
    float total = 0.0;
    for (int k = -radius; k <= radius; ++k) {
        const float weight = exp(falloff * (float)(k * k));
        const float2 at = uv + Step * (float)k;
        total += weight;
        if (all(at >= float2(0.0, 0.0)) && all(at <= Region)) {
            sum += Source.SampleLevel(SourceSampler, at, 0.0) * weight;
        }
    }
    return sum / total;
}
