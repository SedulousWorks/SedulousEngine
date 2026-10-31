// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// A surface shader's forward program, after its text: the engine's vertex stage (with the
// author's Vertex() in it) as VSMain, and a pixel stage, PSMain, that runs Surface() and shades it
// lit (SURFACE_LIT: every light, shadow and reflection probe) or unlit (its albedo and emission),
// keeping the forward pass's contract (the DITHER fade, the ALPHA_TEST cut-out, the five GBUFFER
// targets, the editor's debug views).
#ifndef SURFACE_FORWARD_HLSLI
#define SURFACE_FORWARD_HLSLI

#define FORWARD_VS_ENTRY VSMain
#include "forward_vs.hlsli"
#include "lighting.hlsli"
#include "forward_ps.hlsli"

#ifdef GBUFFER
GBufferOutput PSMain(VSOutput input) {
#else
float4 PSMain(VSOutput input) : SV_Target0 {
#endif
#ifdef DITHER
    ScreenDoorFade(input.clip.xy, input.fade);
#endif
    SurfaceOutput s = SurfaceEvaluate(input.worldPos, input.normalWS, input.tangentWS, input.uv,
                                      input.color, ViewEyeFor(input.worldPos), input.clip,
                                      IblParams.z);
    float alpha = s.alpha;
#ifdef ALPHA_TEST
    if (alpha < SurfaceAlphaCutoff()) { discard; }
#endif
    // The tangent-space normal into world space, as the forward pass maps its normal map;
    // a degenerate tangent keeps the geometric normal.
    float3 N = normalize(input.normalWS);
    {
        float3 T = input.tangentWS.xyz - N * dot(input.tangentWS.xyz, N);
        float  tLen = length(T);
        if (tLen > 1e-4) {
            T /= tLen;
            float3 B = cross(N, T) * input.tangentWS.w;
            N = normalize(s.normal.x * T + s.normal.y * B + s.normal.z * N);
        }
    }
    float viewDepth = -mul(float4(input.worldPos, 1.0), View).z;
#ifdef SURFACE_LIT
    float3 V         = ViewDirToCamera(input.worldPos); // parallel under an orthographic view
    float3 albedo    = s.albedo;
    float  metallic  = saturate(s.metallic);
    float  roughness = clamp(s.roughness, 0.045, 1.0);
    float3 F0        = lerp(float3(0.04, 0.04, 0.04), albedo, metallic);
    uint lightCount;
    float3 litColor = DirectLight(input.clip.xy, input.worldPos, viewDepth, N, V, albedo,
                                  roughness, metallic, F0, lightCount)
                    + AmbientLight(input.worldPos, N, V, albedo, roughness, metallic, F0,
                                   s.occlusion)
                    + s.emissive;
    float3 bounce = albedo * (1.0 - metallic);   // what SSGI's bounce leaves the surface with
#else
    // Unlit: as the built-in unlit, fully rough, not metal, and nothing for SSGI to bounce.
    float3 albedo    = s.albedo;
    float  metallic  = 0.0;
    float  roughness = 1.0;
    uint   lightCount = 0u;
    float3 litColor = s.albedo + s.emissive;
    float3 bounce = float3(0.0, 0.0, 0.0);
#endif
    uint debugMode = (uint)(DebugParams.x + 0.5);
#ifdef GBUFFER
    if (debugMode != 0u) {
        litColor = DebugSemanticColor(debugMode, albedo, N, roughness, metallic, viewDepth,
                                      lightCount, litColor);
        alpha = 1.0;
    }
    GBufferOutput o;
    o.color    = float4(litColor, alpha);
    o.normal   = OctEncode(normalize(mul(float4(N, 0.0), View).xyz));
    o.velocity = MotionVector(input.curClip, input.prevClip);
    o.material = float2(roughness, metallic);
    o.albedo   = float4(bounce, 1.0);
    return o;
#else
    if (debugMode != 0u) {
        litColor = DebugSemanticColor(debugMode, albedo, N, roughness, metallic, viewDepth,
                                      lightCount, litColor);
    }
    return float4(litColor, alpha);
#endif
}

#endif
