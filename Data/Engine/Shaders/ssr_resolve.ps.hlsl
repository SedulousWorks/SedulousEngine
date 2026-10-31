// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "push_constant.hlsli"
Texture2D<float4> ReflTex     : register(t0, space0);   // current reflection (rgb + confidence)
Texture2D<float4> HistoryTex  : register(t1, space0);   // previous accumulated reflection
Texture2D         VelocityTex : register(t2, space0);   // screen-space motion (viewport-local uv delta)
Texture2D<float4> HdrTex      : register(t3, space0);   // scene HDR to composite into
SamplerState      PointSamp   : register(s0, space0);
SamplerState      LinearSamp  : register(s1, space0);

struct SsrResolvePush {
    float2 VpMin;          // view sub-rect origin in full-texture uv
    float2 VpSize;         // view sub-rect size in full-texture uv
    float2 TexelSize;      // 1 / full size
    float  BlendFactor;    // max history weight (~0.9)
    float  HistoryValid;   // 0 = first frame (no history)
    float  VarianceGamma;  // neighborhood clip half-width in stddevs (~1.0)
    float  MotionScale;    // how fast history drops with motion
    int    TemporalOn;     // 0 = skip history blend (pass current through)
    int    Debug;          // >0 = output raw reflection (no composite)
    float  GhostReject;    // history-vs-current luma-diff rejection strength (higher = less ghosting)
};
PUSH_CONSTANT(SsrResolvePush, pc, space1);

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

struct PSOut { float4 Color : SV_Target0; float4 History : SV_Target1; };

PSOut main(float4 pos : SV_Position, float2 uv : TEXCOORD0) {
    float4 curR  = ReflTex.SampleLevel(PointSamp, uv, 0);   // rgb + confidence
    float4 accum = curR;

    if (pc.TemporalOn != 0 && pc.HistoryValid > 0.5 && pc.Debug == 0) {
        float2 localUv = (uv - pc.VpMin) / pc.VpSize;
        float2 vel     = VelocityTex.SampleLevel(PointSamp, uv, 0).rg;   // viewport-local uv delta
        float2 histLoc = localUv - vel;
        if (all(histLoc >= 0.0) && all(histLoc <= 1.0)) {
            // YCoCg neighborhood variance box from the CURRENT reflection (3x3).
            float3 m1 = float3(0,0,0), m2 = float3(0,0,0);
            [unroll] for (int ny = -1; ny <= 1; ++ny) {
                [unroll] for (int nx = -1; nx <= 1; ++nx) {
                    float3 y = RGBToYCoCg(ReflTex.SampleLevel(PointSamp, uv + float2(nx, ny) * pc.TexelSize, 0).rgb);
                    m1 += y; m2 += y * y;
                }
            }
            m1 /= 9.0; m2 /= 9.0;
            float3 sigma  = sqrt(max(m2 - m1 * m1, 0.0));
            float3 boxMin = m1 - pc.VarianceGamma * sigma;
            float3 boxMax = m1 + pc.VarianceGamma * sigma;

            float2 histFull = pc.VpMin + histLoc * pc.VpSize;
            float4 hist    = HistoryTex.SampleLevel(LinearSamp, histFull, 0);
            float3 rawHistY = RGBToYCoCg(hist.rgb);
            float3 histY   = ClipToAABB(rawHistY, boxMin, boxMax);
            float3 curY    = RGBToYCoCg(curR.rgb);
            // Content-change rejection: where the reprojected history's luma disagrees with the current
            // reflection (a moving reflected object trailed into this pixel), drop history and trust current.
            // This is what kills ghosting that surface-velocity reprojection can't (the surface is static
            // but its reflection moved). Plus a motion-adaptive term for camera movement.
            float  ghost = saturate(1.0 - abs(rawHistY.x - curY.x) * pc.GhostReject);
            float  motionMag = saturate(length(vel) * pc.MotionScale);
            float  blend = pc.BlendFactor * (1.0 - 0.5 * motionMag) * ghost;
            accum = float4(max(YCoCgToRGB(lerp(curY, histY, blend)), 0.0), lerp(curR.a, hist.a, blend));
        }
    }

    PSOut o;
    o.History = accum;
    float3 hdr = HdrTex.SampleLevel(PointSamp, uv, 0).rgb;
    o.Color = (pc.Debug > 0) ? float4(accum.rgb, 1.0) : float4(lerp(hdr, accum.rgb, saturate(accum.a)), 1.0);
    return o;
}
