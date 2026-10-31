// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// Auto-exposure measurement + adaptation, one 1x1 pass per view. Samples a fixed grid over the
// view's HDR sub-rect, averages LOG luminance (geometric mean - a bright sun texel cannot drown
// the frame), converts back to linear, then eases the PREVIOUS adapted value toward it
// (exponential eye adaptation; DtSpeed = dt * speed, HistoryValid = 0 on the first frame so the
// value snaps instead of fading in from black).

#include "push_constant.hlsli"
Texture2D<float4> Hdr      : register(t0, space0);
Texture2D<float4> Prev     : register(t1, space0);
SamplerState      Samp     : register(s0, space0);
struct ExposurePush { float2 UvScale; float2 UvOffset; float DtSpeed; float HistoryValid; float Pad0; float Pad1; };
PUSH_CONSTANT(ExposurePush, pc, space1);

float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    const int kGrid = 16;
    const float3 lw = float3(0.2126, 0.7152, 0.0722);
    float sumLog = 0.0;
    [loop] for (int y = 0; y < kGrid; ++y) {
        [loop] for (int x = 0; x < kGrid; ++x) {
            float2 g = (float2(x, y) + 0.5) / kGrid;
            float2 st = pc.UvOffset + g * pc.UvScale;
            float3 c = Hdr.SampleLevel(Samp, st, 0).rgb;
            float luma = max(dot(c, lw), 0.0);
            sumLog += log2(luma + 1e-4);
        }
    }
    float target = exp2(sumLog / (kGrid * kGrid));
    float prev = Prev.SampleLevel(Samp, float2(0.5, 0.5), 0).r;
    float k = 1.0 - exp(-max(pc.DtSpeed, 0.0));
    float adapted = (pc.HistoryValid > 0.5) ? lerp(prev, target, saturate(k)) : target;
    return float4(adapted, 0.0, 0.0, 1.0);
}
