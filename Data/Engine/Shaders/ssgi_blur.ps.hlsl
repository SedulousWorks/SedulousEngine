// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// SSGI spatial denoise: a depth-aware 5x5 sparse cross gather. Run once over the raw trace,
// BETWEEN trace and temporal resolve (at 1-4 rays/pixel the raw estimate is mostly misses +
// occasional hits, so neighbors share their hits first), then again over the ACCUMULATED
// bounce at a widening Step (1, 2, 4, 8: an a-trous filter), so the history can stay close to
// what the frame shows (no trail behind a moving light) without its noise showing as blotches.
// Depth weighting keeps the gather from bleeding across silhouettes.

#include "push_constant.hlsli"
Texture2D<float4> GiTex    : register(t0, space0);   // raw trace (rgb + hit fraction)
Texture2D         DepthTex : register(t1, space0);
SamplerState      PointSamp: register(s0, space0);

struct SsgiBlurPush {
    float2 TexelSize;      // 1 / full size
    float  DepthSigma;     // view-space depth tolerance scale (relative)
    float  Step;           // tap spacing in pixels (the a-trous passes after the accumulate widen it)
    row_major float4x4 InvProj;
    float2 VpMin;
    float2 VpSize;
    float  YSign;
    float  _pad1;
};
PUSH_CONSTANT(SsgiBlurPush, pc, space1);

float LinearDepth(float2 uv) {
    float d = DepthTex.SampleLevel(PointSamp, uv, 0).r;
    float2 luv = (uv - pc.VpMin) / pc.VpSize;
    float2 ndc = float2(luv.x * 2.0 - 1.0, (luv.y * 2.0 - 1.0) * pc.YSign);
    float4 h = mul(float4(ndc, d, 1.0), pc.InvProj);
    return -(h.z / h.w);
}

float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    float4 center = GiTex.SampleLevel(PointSamp, uv, 0);
    float  cd = LinearDepth(uv);

    // Sparse 5x5 cross + diagonals (13 taps): wide enough to find neighbors' hits,
    // cheap enough for full-res. Gaussian-ish falloff by ring.
    const float2 kOffsets[12] = {
        float2( 1, 0), float2(-1, 0), float2(0,  1), float2(0, -1),
        float2( 1, 1), float2(-1, 1), float2(1, -1), float2(-1, -1),
        float2( 2, 0), float2(-2, 0), float2(0,  2), float2(0, -2)
    };
    const float kRingW[12] = { 0.75, 0.75, 0.75, 0.75,
                               0.5,  0.5,  0.5,  0.5,
                               0.35, 0.35, 0.35, 0.35 };

    float4 sum = center;
    float  wsum = 1.0;
    float  tol = max(cd * pc.DepthSigma, 0.02);   // relative depth tolerance
    [unroll] for (int i = 0; i < 12; ++i) {
        float2 su = uv + kOffsets[i] * pc.Step * pc.TexelSize;
        float  sd = LinearDepth(su);
        float  w = kRingW[i] * saturate(1.0 - abs(sd - cd) / tol);
        sum  += GiTex.SampleLevel(PointSamp, su, 0) * w;
        wsum += w;
    }
    return sum / wsum;
}
