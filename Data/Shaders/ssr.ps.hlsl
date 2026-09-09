// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "push_constant.hlsli"
Texture2D<float4> SceneTex    : register(t0, space0);   // lit HDR (reflected + composited into)
Texture2D         DepthTex    : register(t1, space0);
Texture2D         NormalTex   : register(t2, space0);   // octahedral view-space normal
Texture2D         MaterialTex : register(t3, space0);   // R=roughness, G=metallic
SamplerState      PointSamp   : register(s0, space0);   // depth / reconstruction (exact)
SamplerState      LinearSamp  : register(s1, space0);   // glossy color cone-gather

// 12-tap Poisson disk (unit radius) for the roughness cone-gather.
static const float2 kPoisson12[12] = {
    float2(-0.326, -0.406), float2(-0.840, -0.074), float2(-0.696,  0.457),
    float2(-0.203,  0.621), float2( 0.962, -0.195), float2( 0.473, -0.480),
    float2( 0.519,  0.767), float2( 0.185, -0.893), float2( 0.507,  0.064),
    float2( 0.896,  0.412), float2(-0.322, -0.933), float2(-0.792, -0.598)
};

struct SsrPush {
    row_major float4x4 InvProj;   // (viewport-local ndc, depth) -> view space
    float2 VpMin;                 // this view's sub-rect origin in FULL-texture uv
    float2 VpSize;                // this view's sub-rect size in FULL-texture uv
    float2 Jitter;                // projection z-row (proj(2,0), proj(2,1)): jittered ndc match
    float  ProjXX;                // projection(0,0): view.x -> ndc.x
    float  ProjYY;                // projection(1,1): view.y -> ndc.y
    float  Thickness;             // view-space linear-depth acceptance band (hit thickness)
    float  Intensity;             // reflection strength multiplier
    float  EdgeFade;              // uv fraction from each border over which SSR fades out
    float  RoughnessCutoff;       // roughness at/above which SSR is fully off (fades to IBL)
    int    MaxSteps;             // march step budget
    float  YSign;                // scene-NDC Y sign for uv<->ndc: -1 Vulkan (neg viewport), +1 Y-flip targets
    int    Debug;                // 0=off, 1=raw reflected color, 2=hit uv, 3=weight, 4=reflect dir
    float  Glossy;               // glossy cone-gather scale (0 = sharp mirror)
};
PUSH_CONSTANT(SsrPush, pc, space1);

// Octahedral decode -> view-space normal (matches the forward's OctEncode).
float3 OctDecode(float2 e) {
    float3 n = float3(e.xy, 1.0 - abs(e.x) - abs(e.y));
    float  t = saturate(-n.z);
    n.x += n.x >= 0.0 ? -t : t;
    n.y += n.y >= 0.0 ? -t : t;
    return normalize(n);
}
// viewport-LOCAL uv (0..1 within the view) + depth -> view-space position. The uv<->ndc Y
// mapping is backend-driven (YSign, same convention as ShadowParams.y): Vulkan's negative
// viewport gives uv.y = (1-ndc.y)/2, Y-flip targets (WebGPU) uv.y = (1+ndc.y)/2 - with the
// wrong sign every reconstructed view position mirrors and reflections trace the wrong way.
float3 ViewPos(float2 luv, float depth) {
    float2 ndc = float2(luv.x * 2.0 - 1.0, (luv.y * 2.0 - 1.0) * pc.YSign);
    float4 h = mul(float4(ndc, depth, 1.0), pc.InvProj);
    return h.xyz / h.w;
}
// view-space position -> viewport-LOCAL uv (jitter-aware). Diagonal proj terms + w = -view.z.
float2 ViewToLocal(float3 vp) {
    float2 ndc = float2(vp.x * pc.ProjXX, vp.y * pc.ProjYY) / max(-vp.z, 1e-4) - pc.Jitter;
    return float2(ndc.x * 0.5 + 0.5, ndc.y * pc.YSign * 0.5 + 0.5);
}
float2 LocalToFull(float2 luv) { return pc.VpMin + luv * pc.VpSize; }   // local uv -> full-texture uv (sampling)
float2 FullToLocal(float2 fuv) { return (fuv - pc.VpMin) / pc.VpSize; } // full-texture uv -> local uv
// Interleaved-gradient noise (denoises cleanly under TAA; frame-rotated so TAA averages it out).
float Ign(float2 p) { return frac(52.9829189 * frac(dot(p, float2(0.06711056, 0.00583715)))); }

// Trace outputs the REFLECTION buffer (rgb = reflected radiance, a = confidence/weight). Compositing
// into the HDR happens in the resolve pass (after temporal accumulation). No reflection -> (0,0,0,0).
float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    float  depth = DepthTex.SampleLevel(PointSamp, uv, 0).r;
    if (depth >= 1.0) { return float4(0.0, 0.0, 0.0, 0.0); }   // background: no reflector

    float2 mat       = MaterialTex.SampleLevel(PointSamp, uv, 0).rg;
    float  roughness = mat.r;
    float  metallic  = mat.g;
    // Rough surfaces fall back to the IBL/probe reflection already in the HDR (SSR is a sharp mirror term).
    float  roughFade = saturate(1.0 - roughness / max(pc.RoughnessCutoff, 1e-3));
    if (roughFade <= 0.0) { return float4(0.0, 0.0, 0.0, 0.0); }

    float2 luv = FullToLocal(uv);                 // this pixel's viewport-local uv
    float3 P = ViewPos(luv, depth);
    float3 N = OctDecode(NormalTex.SampleLevel(PointSamp, uv, 0).rg);
    float3 V = normalize(-P);
    float3 R = reflect(-V, N);                     // view-space reflection ray
    if (pc.Debug == 4) { return float4(R * 0.5 + 0.5, 1.0); }

    // Endpoint in view space (length scales with distance). If the reflection points toward the camera
    // (R.z > 0), clamp so the endpoint stays in front of the near plane.
    float rayLen = max(2.0, -P.z);
    if (R.z > 1e-4) { rayLen = min(rayLen, max((-0.05 - P.z) / R.z, 0.0)); }
    float3 endVS = P + R * rayLen;

    // Segment in viewport-local uv; 1/w interpolated linearly along it (perspective-correct depth).
    float2 luv0 = luv;
    float2 luv1 = ViewToLocal(endVS);
    float  iz0 = 1.0 / max(-P.z, 1e-4);
    float  iz1 = 1.0 / max(-endVS.z, 1e-4);

    // Clamp the far end to the viewport box [0,1]^2 so all MaxSteps land on-screen (max sample density).
    float2 d = luv1 - luv0;
    float2 dsgn = float2(d.x >= 0.0 ? 1.0 : -1.0, d.y >= 0.0 ? 1.0 : -1.0);
    d = dsgn * max(abs(d), float2(1e-6, 1e-6));   // avoid divide-by-zero on axis-aligned segments
    float2 tTo0 = (float2(0.0, 0.0) - luv0) / d;
    float2 tTo1 = (float2(1.0, 1.0) - luv0) / d;
    float2 tHi  = max(tTo0, tTo1);                 // exit parameter per axis
    float  tExit = clamp(min(min(tHi.x, tHi.y), 1.0), 0.0, 1.0);
    luv1 = luv0 + (luv1 - luv0) * tExit;
    iz1  = lerp(iz0, iz1, tExit);                  // 1/w is linear in the segment parameter

    // Static per-pixel dither: deterministic per (pixel, camera), so the temporal accumulation is
    // stable under a still camera while ghost-reject handles moving reflected content. (The frame-
    // rotated variant lived in this slot before it was repurposed for YSign; dither stays static.)
    float jit = frac(Ign(pos.xy));
    bool  hit = false;
    float jHit = 0.0, jPrev = 0.0;
    [loop] for (int i = 1; i <= pc.MaxSteps; ++i) {
        float  j = (float(i) - jit) / float(pc.MaxSteps);
        float2 ls = lerp(luv0, luv1, j);
        if (any(ls < 0.0) || any(ls > 1.0)) { break; }         // left the viewport
        float  sd = DepthTex.SampleLevel(PointSamp, LocalToFull(ls), 0).r;
        if (sd >= 1.0) { jPrev = j; continue; }                // sky: nothing to hit
        float  rayLin  = 1.0 / lerp(iz0, iz1, j);              // ray linear depth (= -view.z)
        float  surfLin = -ViewPos(ls, sd).z;                   // stored surface linear depth
        float  dif = rayLin - surfLin;                         // >0 once the ray passes behind the surface
        if (dif > 0.05 && dif < pc.Thickness) { hit = true; jHit = j; break; }
        jPrev = j;
    }
    if (!hit) { return float4(0.0, 0.0, 0.0, 0.0); }   // miss: no reflection (resolve keeps the HDR)

    // Binary refine the crossing within [jPrev, jHit] for a sub-pixel-sharp hit (4 iters).
    float a = jPrev, b = jHit;
    [unroll] for (int r = 0; r < 4; ++r) {
        float  m = 0.5 * (a + b);
        float2 mls = lerp(luv0, luv1, m);
        float  mSurf = -ViewPos(mls, DepthTex.SampleLevel(PointSamp, LocalToFull(mls), 0).r).z;
        if (1.0 / lerp(iz0, iz1, m) - mSurf > 0.0) { b = m; } else { a = m; }
    }
    float2 hitLocal = lerp(luv0, luv1, b);
    float2 hitFull  = LocalToFull(hitLocal);

    // Glossy cone-gather: average the reflected color over a disk whose radius grows with roughness and
    // ray-travel distance (rougher / farther = blurrier). Near-mirror surfaces stay razor-sharp. Taps are
    // clamped to this view's sub-rect so a rough reflection never bleeds in the other split-screen view.
    float  segLen = length(hitLocal - luv);
    float  coneR  = pc.Glossy * roughness * (0.015 + 0.18 * segLen);   // viewport-local blur radius (0 = sharp)
    float3 refl;
    if (coneR < 2e-4) {
        refl = SceneTex.SampleLevel(LinearSamp, hitFull, 0).rgb;
    } else {
        refl = float3(0.0, 0.0, 0.0);
        float2 lo = pc.VpMin + 1e-4;
        float2 hi = pc.VpMin + pc.VpSize - 1e-4;
        [unroll] for (int gi = 0; gi < 12; ++gi) {
            float2 s = clamp(hitFull + kPoisson12[gi] * coneR * pc.VpSize, lo, hi);
            refl += SceneTex.SampleLevel(LinearSamp, s, 0).rgb;
        }
        refl *= (1.0 / 12.0);
    }
    // Screen-edge fade (off-screen has no data) on the LOCAL uv + Fresnel + roughness gate. LERP-replace
    // so the SSR term stands in for the IBL specular rather than adding to it.
    float2 e = smoothstep(0.0, pc.EdgeFade, hitLocal) * smoothstep(0.0, pc.EdgeFade, 1.0 - hitLocal);
    float  edgeFade = e.x * e.y;
    float  NdotV = saturate(dot(N, V));
    float  F0 = lerp(0.04, 1.0, metallic);
    float  fresnel = F0 + (1.0 - F0) * pow(1.0 - NdotV, 5.0);
    float  weight = saturate(edgeFade * fresnel * roughFade * pc.Intensity);
    if (pc.Debug == 2) { return float4(hitLocal, 0.0, 1.0); }         // hit uv (R=x, G=y, viewport-local)
    if (pc.Debug == 3) { return float4(weight, weight, weight, 1.0); }// composite weight
    return float4(refl, weight);   // rgb = reflected radiance, a = confidence
}
