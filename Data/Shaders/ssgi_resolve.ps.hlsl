// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// SSGI temporal resolve + composite - ssr_resolve's diffuse twin. Reproject + variance-clip +
// accumulate the noisy trace (rgb = bounce, a = the hemisphere share hits stood in for), then
// composite: out = hdr + albedo * (bounce - hitShare * skyRadiance) * Intensity. The forward lit
// the surface with the sky's ambient as if nothing were in the way; where a ray hit geometry the
// bounce replaces that sky, so the composite takes that share of it back out (occluded corners
// darken) and adds what was really there, tinted by the surface's diffuse albedo. skyRadiance is
// the pixel's own ambient: the scene's SH sky over its normal (EvalSH9 / PI, scaled by the
// sky-lighting dimmer; skipped when the scene has none) plus the flat fill - the forward's terms.

#include "push_constant.hlsli"
Texture2D<float4> GiTex       : register(t0, space0);   // current trace (rgb + hit fraction)
Texture2D<float4> HistoryTex  : register(t1, space0);   // previous accumulated GI
Texture2D         VelocityTex : register(t2, space0);   // screen-space motion (viewport-local uv delta)
Texture2D<float4> HdrTex      : register(t3, space0);   // scene HDR to composite into
Texture2D<float4> AlbedoTex   : register(t4, space0);   // G-buffer diffuse albedo
Texture2D         NormalTex   : register(t5, space0);   // octahedral view-space normal
StructuredBuffer<float4> IblSH : register(t6, space0);  // the scene's SH9 irradiance (as forward t5)
SamplerState      PointSamp   : register(s0, space0);
SamplerState      LinearSamp  : register(s1, space0);

struct SsgiResolvePush {
    float2 VpMin;
    float2 VpSize;
    float2 TexelSize;
    float  BlendFactor;    // max history weight (~0.92 - GI is noisier than SSR, lean on history)
    float  HistoryValid;   // 0 = first frame (no history)
    float  VarianceGamma;  // neighborhood clip half-width in stddevs
    float  MotionScale;    // how fast history drops with motion
    int    TemporalOn;     // 0 = skip history blend
    int    Debug;          // >0 = output the accumulated GI raw (no composite)
    float  GhostReject;    // history-vs-current luma-diff rejection strength
    float  Intensity;      // GI strength
    float4 ViewToWorld0;   // rows of the camera's world rotation: view-space normal -> world
    float4 ViewToWorld1;
    float4 ViewToWorld2;
    float4 SkyAmbient;     // rgb = flat ambient fill, w = SH sky dimmer (0 = no SH sky)
};
PUSH_CONSTANT(SsgiResolvePush, pc, space1);

static const float PI = 3.14159265;

float3 OctDecode(float2 e) {
    float3 n = float3(e.xy, 1.0 - abs(e.x) - abs(e.y));
    float  t = saturate(-n.z);
    n.x += n.x >= 0.0 ? -t : t;
    n.y += n.y >= 0.0 ? -t : t;
    return normalize(n);
}
// The forward's SH9 irradiance in direction n (forward.ps.hlsl EvalSH9).
float3 EvalSH9(float3 n) {
    float3 r = IblSH[0].rgb * 0.886227;
    r += IblSH[1].rgb * (2.0 * 0.511664 * n.y);
    r += IblSH[2].rgb * (2.0 * 0.511664 * n.z);
    r += IblSH[3].rgb * (2.0 * 0.511664 * n.x);
    r += IblSH[4].rgb * (2.0 * 0.429043 * n.x * n.y);
    r += IblSH[5].rgb * (2.0 * 0.429043 * n.y * n.z);
    r += IblSH[6].rgb * (0.743125 * (3.0 * n.z * n.z - 1.0));
    r += IblSH[7].rgb * (2.0 * 0.429043 * n.x * n.z);
    r += IblSH[8].rgb * (0.429043 * (n.x * n.x - n.y * n.y));
    return max(r, 0.0);
}
// The ambient radiance the forward lit this pixel with (diffuse = albedo * this).
float3 SkyRadiance(float2 uv) {
    float3 sky = pc.SkyAmbient.rgb;
    if (pc.SkyAmbient.w > 0.0) {
        float3 nv = OctDecode(NormalTex.SampleLevel(PointSamp, uv, 0).rg);
        float3 nw = normalize(nv.x * pc.ViewToWorld0.xyz + nv.y * pc.ViewToWorld1.xyz + nv.z * pc.ViewToWorld2.xyz);
        sky += EvalSH9(nw) / PI * pc.SkyAmbient.w;
    }
    return sky;
}

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
    float4 curG  = GiTex.SampleLevel(PointSamp, uv, 0);   // rgb + hit fraction
    float4 accum = curG;

    if (pc.TemporalOn != 0 && pc.HistoryValid > 0.5 && pc.Debug == 0) {
        float2 localUv = (uv - pc.VpMin) / pc.VpSize;
        float2 vel     = VelocityTex.SampleLevel(PointSamp, uv, 0).rg;
        float2 histLoc = localUv - vel;
        if (all(histLoc >= 0.0) && all(histLoc <= 1.0)) {
            float3 m1 = float3(0,0,0), m2 = float3(0,0,0);
            [unroll] for (int ny = -1; ny <= 1; ++ny) {
                [unroll] for (int nx = -1; nx <= 1; ++nx) {
                    float3 y = RGBToYCoCg(GiTex.SampleLevel(PointSamp, uv + float2(nx, ny) * pc.TexelSize, 0).rgb);
                    m1 += y; m2 += y * y;
                }
            }
            m1 /= 9.0; m2 /= 9.0;
            float3 sigma  = sqrt(max(m2 - m1 * m1, 0.0));
            float3 boxMin = m1 - pc.VarianceGamma * sigma;
            float3 boxMax = m1 + pc.VarianceGamma * sigma;

            float2 histFull = pc.VpMin + histLoc * pc.VpSize;
            float4 hist    = HistoryTex.SampleLevel(LinearSamp, histFull, 0);
            // Self-heal: a NaN that ever reaches the ping-pong history would otherwise
            // live forever (lerp with NaN is NaN). No isnan: naga cannot translate
            // OpIsNan (WGSL removed isNan) - NaN fails hist == hist instead
            // (select = OpSelect, naga-safe); clamp's min/max eat infinities.
            hist.rgb = select(hist.rgb == hist.rgb, clamp(hist.rgb, 0.0, 65504.0),
                              float3(0.0, 0.0, 0.0));
            float3 rawHistY = RGBToYCoCg(hist.rgb);
            float3 curY    = RGBToYCoCg(curG.rgb);
            // Ghost-reject ONLY when HISTORY is the bright outlier (a trailing glow after
            // light moved away). A bright CURRENT outlier is precisely what accumulation
            // must average away - dropping history on it was the firefly FLASH path.
            float  ghost = saturate(1.0 - max(rawHistY.x - curY.x, 0.0) * pc.GhostReject);
            float  motionMag = saturate(length(vel) * pc.MotionScale);
            // Variance-clip only under motion / ghost suspicion. When the camera is still
            // the clip is the OTHER flash path: a blurred firefly elevates its whole 3x3
            // neighborhood, so the box sits at the blob and drags trusted history up into
            // it regardless of blend weight. Still + trusted history = raw accumulation;
            // the estimator variance then dies at blend^n as intended.
            float  clipStrength = saturate(motionMag + (1.0 - ghost));
            float3 histY = lerp(rawHistY, ClipToAABB(rawHistY, boxMin, boxMax), clipStrength);
            float  blend = pc.BlendFactor * (1.0 - 0.5 * motionMag) * ghost;
            accum = float4(max(YCoCgToRGB(lerp(curY, histY, blend)), 0.0), lerp(curG.a, hist.a, blend));
        }
    }

    PSOut o;
    o.History = accum;
    float3 hdr = HdrTex.SampleLevel(PointSamp, uv, 0).rgb;
    float3 albedo = AlbedoTex.SampleLevel(PointSamp, uv, 0).rgb;
    float3 bounce = accum.rgb - accum.a * SkyRadiance(uv); // what the hits found, less the sky they hid
    o.Color = (pc.Debug > 0) ? float4(accum.rgb, 1.0)
                             : float4(max(hdr + albedo * bounce * pc.Intensity, 0.0), 1.0);
    return o;
}
