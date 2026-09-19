// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "push_constant.hlsli"
Texture2D    CurrentColor  : register(t0, space0);
Texture2D    HistoryColor  : register(t1, space0);
Texture2D    MotionVectors : register(t2, space0);
Texture2D    DepthTexture  : register(t3, space0);
SamplerState PointSamp     : register(s0, space0);
SamplerState LinearSamp    : register(s1, space0);

struct TaaPush {
    float2 TexelSize;      // 1 / size
    float  BlendFactor;    // max history weight on stable pixels (~0.97)
    float  HistoryValid;   // 0 = first frame (no history)
    float  VarianceGamma;  // neighborhood clip box half-width in stddevs (~1.25; larger = softer/steadier)
    float  MotionScale;    // how fast history is dropped as motion grows (0 = ignore motion)
    float  NearPlane;      // camera near - linearize depth for the disocclusion test
    float  FarPlane;       // camera far
};
PUSH_CONSTANT(TaaPush, pc, space1);

// Linearize the NDC depth (depth.hlsli's convention) to view-space Z, so the disocclusion threshold is
// depth-independent. Sky/background (kDepthFar) maps to FarPlane; there's no divide-by-zero in [0,1].
#include "depth.hlsli"

float  Luminance(float3 c)  { return dot(c, float3(0.2126, 0.7152, 0.0722)); }
float3 RGBToYCoCg(float3 c) { return float3(0.25*c.r + 0.5*c.g + 0.25*c.b, 0.5*c.r - 0.5*c.b, -0.25*c.r + 0.5*c.g - 0.25*c.b); }
float3 YCoCgToRGB(float3 c) { float t = c.x - c.z; return float3(t + c.y, c.x + c.z, t - c.y); }

float3 ClipToAABB(float3 color, float3 aabbMin, float3 aabbMax) {
    float3 center  = (aabbMax + aabbMin) * 0.5;
    float3 extents = (aabbMax - aabbMin) * 0.5;
    float3 shift   = color - center;
    float3 absUnit = abs(shift / max(extents, 1e-4));
    float  maxUnit = max(max(absUnit.x, absUnit.y), absUnit.z);
    return maxUnit > 1.0 ? center + (shift / maxUnit) : color;
}

// 5-tap Catmull-Rom (Karis) - sharp bicubic history reconstruction from a bilinear sampler.
float3 SampleHistoryCatmullRom(float2 uv, float2 texSize) {
    float2 samplePos = uv * texSize;
    float2 tc1 = floor(samplePos - 0.5) + 0.5;
    float2 f  = samplePos - tc1;
    float2 w0 = f * (-0.5 + f * (1.0 - 0.5 * f));
    float2 w1 = 1.0 + f * f * (-2.5 + 1.5 * f);
    float2 w2 = f * (0.5 + f * (2.0 - 1.5 * f));
    float2 w3 = f * f * (-0.5 + 0.5 * f);
    float2 w12 = w1 + w2;
    float2 tc0  = (tc1 - 1.0) / texSize;
    float2 tc3  = (tc1 + 2.0) / texSize;
    float2 tc12 = (tc1 + w2 / w12) / texSize;
    float3 r = float3(0,0,0); float wSum = 0.0;
    r += HistoryColor.SampleLevel(LinearSamp, float2(tc12.x, tc0.y),  0).rgb * (w12.x * w0.y);  wSum += w12.x * w0.y;
    r += HistoryColor.SampleLevel(LinearSamp, float2(tc0.x,  tc12.y), 0).rgb * (w0.x  * w12.y); wSum += w0.x  * w12.y;
    r += HistoryColor.SampleLevel(LinearSamp, float2(tc12.x, tc12.y), 0).rgb * (w12.x * w12.y); wSum += w12.x * w12.y;
    r += HistoryColor.SampleLevel(LinearSamp, float2(tc3.x,  tc12.y), 0).rgb * (w3.x  * w12.y); wSum += w3.x  * w12.y;
    r += HistoryColor.SampleLevel(LinearSamp, float2(tc12.x, tc3.y),  0).rgb * (w12.x * w3.y);  wSum += w12.x * w3.y;
    return max(r / max(wSum, 1e-5), 0.0);
}

struct PSOut { float4 Color : SV_Target0; float4 History : SV_Target1; };

PSOut main(float4 pos : SV_Position, float2 uv : TEXCOORD0) {
    // Full-screen post pass: every texture here is a 1:1 single-mip target, so all taps use SampleLevel
    // at mip 0. This is exact (no mip chain to select) AND keeps sampling out of the implicit-derivative
    // path - WGSL/Chrome make textureSample in non-uniform control flow (the loops below) a hard error.
    float3 current = CurrentColor.SampleLevel(PointSamp, uv, 0).rgb;

    // This pixel's surface depth (linear) - stored in the history alpha so next frame can compare against
    // it at the reprojected position (the disocclusion test below).
    float centerLin = LinearizeDepth(DepthTexture.SampleLevel(PointSamp, uv, 0).r, pc.NearPlane, pc.FarPlane);

    // Closest depth in a 3x3 neighborhood -> stable motion-vector selection (reduces silhouette ghosting).
    float  closestDepth = FarthestDepth();
    float2 closestUV    = uv;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            float2 s = uv + float2(x, y) * pc.TexelSize;
            float  d = DepthTexture.SampleLevel(PointSamp, s, 0).r;
            if (IsNearerDepth(d, closestDepth)) { closestDepth = d; closestUV = s; }
        }
    }
    float2 motion    = MotionVectors.SampleLevel(PointSamp, closestUV, 0).rg;
    float2 historyUV = uv - motion;

    PSOut o;
    if (pc.HistoryValid < 0.5 || any(historyUV < 0.0) || any(historyUV > 1.0)) {
        o.Color = float4(current, 1.0); o.History = float4(current, centerLin); return o;
    }

    // Depth-based disocclusion reject: the previous frame's linear depth at historyUV lives in the history
    // alpha. If it disagrees with this frame's (closest) linear depth beyond a relative threshold, the
    // reprojected texel sampled a different surface (occluder revealed / geometry newly occluded) -> drop
    // history to avoid a ghost-on-reveal. linPrev==0 only where no depth was ever stored -> skip the test.
    //
    // Gate it on real motion: disocclusion can only happen when something moves, but at a STATIC silhouette
    // the TAA jitter flips each boundary pixel's coverage (near plane <-> far sky) every frame. That depth
    // flip is not a reveal - it is the sub-pixel coverage we want history to ACCUMULATE into an AA'd edge.
    // Without the gate the reject fires on every boundary pixel each frame, so the edge shows the raw
    // jittered current and the jaggies crawl. Motion is geometric (jitter-free) so static == exactly 0.
    float linPrev  = HistoryColor.SampleLevel(PointSamp, historyUV, 0).a;
    float motionPx = length(motion / pc.TexelSize);   // motion-vector magnitude in pixels
    if (linPrev > 0.0 && motionPx > 0.5) {
        float linCur   = LinearizeDepth(closestDepth, pc.NearPlane, pc.FarPlane);
        float relDiff  = abs(linCur - linPrev) / max(min(linCur, linPrev), 0.001);
        if (relDiff > 0.1) { o.Color = float4(current, 1.0); o.History = float4(current, centerLin); return o; }
    }

    // YCoCg neighborhood statistics: mean (m1) + mean-of-squares (m2) over the 3x3 -> variance box.
    float3 m1 = float3(0,0,0), m2 = float3(0,0,0);
    for (int ny = -1; ny <= 1; ++ny) {
        for (int nx = -1; nx <= 1; ++nx) {
            float3 y = RGBToYCoCg(CurrentColor.SampleLevel(PointSamp, uv + float2(nx, ny) * pc.TexelSize, 0).rgb);
            m1 += y; m2 += y * y;
        }
    }
    m1 /= 9.0; m2 /= 9.0;
    float3 sigma  = sqrt(max(m2 - m1 * m1, 0.0));
    float3 boxMin = m1 - pc.VarianceGamma * sigma;
    float3 boxMax = m1 + pc.VarianceGamma * sigma;

    // Catmull-Rom history, clipped (in YCoCg) to the variance box toward its center.
    float3 texSize   = float3(1.0 / pc.TexelSize.x, 1.0 / pc.TexelSize.y, 0.0);
    float3 curY      = RGBToYCoCg(current);
    float3 histY     = RGBToYCoCg(SampleHistoryCatmullRom(historyUV, texSize.xy));
    histY            = ClipToAABB(histY, boxMin, boxMax);

    // Blend: fixed-high history weight for stability; the variance clip (above) already handles change
    // and disocclusion, so we DON'T reduce blend on luma mismatch (that collapsed to the jittered current
    // at edges -> wobble). Only real motion drops history a little (less smear on fast movement).
    float motionMag = saturate(length(motion) * pc.MotionScale);   // UV-delta; drops history as it grows
    float blend     = pc.BlendFactor * (1.0 - 0.5 * motionMag);

    float3 result = YCoCgToRGB(lerp(curY, histY, blend));
    result = max(result, 0.0);
    o.Color = float4(result, 1.0); o.History = float4(result, centerLin); return o;
}
