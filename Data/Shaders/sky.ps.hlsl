// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "sky_common.hlsli"

TextureCube  EnvMap  : register(t0, space0);
SamplerState EnvSamp : register(s0, space0);
struct PSIn { float4 pos : SV_Position; float3 dir : TEXCOORD0; float2 ndc : TEXCOORD1; };
struct PSOut { float4 color : SV_Target0; float2 velocity : SV_Target1; };
PSOut main(PSIn i) {
    float3 dir = normalize(i.dir);
    // The env cube already carries skyIntensity (baked once; drives IBL too). CamPosIntensity.w is
    // the SEPARATE display-only backdrop multiplier - it dims the VISIBLE sky without touching the
    // IBL lighting derived from the cube. (skyIntensity is never re-applied here - that squared it.)
    float3 c = EnvMap.SampleLevel(EnvSamp, dir, 0.0).rgb * CamPosIntensity.w;
    // Crisp analytic sun disc (screen resolution, round) toward the light, with a soft ~1.5deg edge.
    float3 L     = normalize(-SunDir.xyz);
    float  cd    = dot(dir, L);
    float  inner = cos(radians(max(SunDir.w, 0.1)));
    float  outer = cos(radians(max(SunDir.w, 0.1) + 1.5));
    c += smoothstep(outer, inner, cd) * SunColor.rgb * SunColor.w;

    // Camera-motion velocity: reproject the (infinite) view ray through last frame's view-proj (w=0, a
    // direction) and take the UV delta, in UNJITTERED NDC. The ray is reconstructed through the UNJITTERED
    // InvViewProj (so the background is temporally invariant under a static camera - no per-pixel jitter
    // oscillation for TAA to chase), which makes i.ndc the geometric current NDC directly. The previous
    // term still unjitters (PrevViewProj carries last frame's jitter; +Jitter.zw removes it).
    float4 prevClip = mul(float4(dir, 0.0), PrevViewProj);
    float2 curNDC   = i.ndc;
    float2 prevNDC  = prevClip.xy / prevClip.w + Jitter.zw;
    float2 velocity = (curNDC - prevNDC) * float2(0.5, -0.5);

    PSOut o; o.color = float4(c, 1.0); o.velocity = velocity; return o;
}
