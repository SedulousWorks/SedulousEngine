// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "bloom_common.hlsli"

float3 Prefilter(float3 c) {
    float br   = max(c.r, max(c.g, c.b));
    float soft = clamp(br - pc.Threshold + pc.Knee, 0.0, 2.0 * pc.Knee);
    soft       = (soft * soft) / (4.0 * pc.Knee + 1e-5);
    float contrib = max(soft, br - pc.Threshold) / max(br, 1e-5);
    return c * contrib;
}
float KarisWeight(float3 c) { return 1.0 / (1.0 + max(c.r, max(c.g, c.b))); }
float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    float2 t = pc.SrcTexel;
    float3 a = Src.SampleLevel(Samp, uv + t * float2(-2,-2), 0).rgb;
    float3 b = Src.SampleLevel(Samp, uv + t * float2( 0,-2), 0).rgb;
    float3 c = Src.SampleLevel(Samp, uv + t * float2( 2,-2), 0).rgb;
    float3 d = Src.SampleLevel(Samp, uv + t * float2(-2, 0), 0).rgb;
    float3 e = Src.SampleLevel(Samp, uv,                     0).rgb;
    float3 f = Src.SampleLevel(Samp, uv + t * float2( 2, 0), 0).rgb;
    float3 g = Src.SampleLevel(Samp, uv + t * float2(-2, 2), 0).rgb;
    float3 h = Src.SampleLevel(Samp, uv + t * float2( 0, 2), 0).rgb;
    float3 i = Src.SampleLevel(Samp, uv + t * float2( 2, 2), 0).rgb;
    float3 j = Src.SampleLevel(Samp, uv + t * float2(-1,-1), 0).rgb;
    float3 k = Src.SampleLevel(Samp, uv + t * float2( 1,-1), 0).rgb;
    float3 l = Src.SampleLevel(Samp, uv + t * float2(-1, 1), 0).rgb;
    float3 m = Src.SampleLevel(Samp, uv + t * float2( 1, 1), 0).rgb;
    float3 result;
    if (pc.FirstPass != 0) {
        // Karis-weighted average of the 5 inner 2x2 groups (firefly suppression), then threshold.
        float3 g0 = (j + k + l + m) * 0.25;
        float3 g1 = (a + b + d + e) * 0.25;
        float3 g2 = (b + c + e + f) * 0.25;
        float3 g3 = (d + e + g + h) * 0.25;
        float3 g4 = (e + f + h + i) * 0.25;
        float w0 = KarisWeight(g0), w1 = KarisWeight(g1), w2 = KarisWeight(g2), w3 = KarisWeight(g3), w4 = KarisWeight(g4);
        result = (g0*w0*0.5 + g1*w1*0.125 + g2*w2*0.125 + g3*w3*0.125 + g4*w4*0.125)
               / max(w0*0.5 + w1*0.125 + w2*0.125 + w3*0.125 + w4*0.125, 1e-5);
        result = Prefilter(result);
    } else {
        result = e * 0.125
               + (a + c + g + i) * 0.03125
               + (b + d + f + h) * 0.0625
               + (j + k + l + m) * 0.125;
    }
    return float4(result, 1.0);
}
