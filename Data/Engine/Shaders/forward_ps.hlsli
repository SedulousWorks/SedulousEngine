// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The forward pixel stage's contract, beside the lighting: the screen-door fade (DITHER), under
// GBUFFER the five targets the post stack reads (colour, view normal, motion vector,
// roughness/metallic, albedo), and the editor's semantic debug views. The engine's forward pass writes them so, and so must a custom
// shader that draws in it.
#ifndef FORWARD_PS_HLSLI
#define FORWARD_PS_HLSLI

#include "view.hlsli"

// The GBUFFER pass's targets.
struct GBufferOutput {
    float4 color    : SV_Target0;   // shaded HDR (tonemapped later)
    float2 normal   : SV_Target1;   // octahedral view-space normal
    float2 velocity : SV_Target2;   // screen-space motion vector (UV delta)
    float2 material : SV_Target3;   // R=roughness, G=metallic (for SSR)
    float4 albedo   : SV_Target4;   // rgb = diffuse albedo (SSGI tints its bounce by it)
};

// A faded mesh (a cutaway wall): drop the share `fade` of its pixels by a 4x4 ordered pattern,
// before any shading. Thresholds run (0.5 .. 15.5) / 16, so 0 keeps every pixel and 1 none;
// TAA's jitter blends what is left toward a see-through wall. `screenPos` is SV_Position.xy.
void ScreenDoorFade(float2 screenPos, float fade) {
    static const float kBayer[16] = { 0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5 };
    uint2 cell = uint2(screenPos) & 3u;
    if (fade > (kBayer[cell.y * 4u + cell.x] + 0.5) / 16.0) { discard; }
}

// Octahedral encode a unit vector -> [-1,1]^2 (full sphere, no sign ambiguity). Used to pack the
// view-space normal into the RG16F G-buffer target for the post stack (GTAO/TAA).
float2 OctEncode(float3 n) {
    n /= (abs(n.x) + abs(n.y) + abs(n.z));
    float2 e = n.xy;
    if (n.z < 0.0) { e = (1.0 - abs(float2(e.y, e.x))) * float2(e.x >= 0.0 ? 1.0 : -1.0, e.y >= 0.0 ? 1.0 : -1.0); }
    return e;
}

// Motion vector: current vs previous screen position, both UNJITTERED so only geometric motion
// remains (else the TAA reprojection wobbles with the jitter). The jitter added to projection(2,0/1)
// shifts NDC by -Jitter (RH: clip.w = -viewZ), so we ADD Jitter back to recover the geometric NDC.
// NDC.y is flipped vs UV.y, hence the (0.5, -0.5) scale. `curClip` and `prevClip` are the vertex
// stage's (VSOutput).
float2 MotionVector(float4 curClip, float4 prevClip) {
    float2 curNDC  = curClip.xy  / curClip.w  + Jitter.xy;
    float2 prevNDC = prevClip.xy / prevClip.w + Jitter.zw;
    return (curNDC - prevNDC) * float2(0.5, -0.5);
}

// Editor semantic debug views (DebugParams.x, ViewDebugSemantic; 0 = off). A uniform
// branch - every lane takes the same path, free when off; kept out of Material/variant
// space on purpose (the drift lint never sees it). Values are meant to reach the screen
// RAW (the compose blits scene color past tonemap when a semantic mode is active).
float3 DebugSemanticColor(uint mode, float3 albedo, float3 N, float roughness, float metallic,
                          float viewDepth, uint lightCount, float3 lit) {
    if (mode == 1u) { return albedo; }
    if (mode == 2u) { return N * 0.5 + 0.5; }
    if (mode == 3u) { return roughness.xxx; }
    if (mode == 4u) { return metallic.xxx; }
    if (mode == 5u) {
        // CSM cascade selection tinted over albedo luma (red/green/blue/yellow, grey = no shadow).
        float luma = dot(albedo, float3(0.299, 0.587, 0.114));
        int count = (int)ShadowCascadeCount;
        float3 tint = float3(0.55, 0.55, 0.55);
        if (count > 0) {
            int cascade = count - 1;
            [unroll] for (int i = 0; i < 4; ++i) {
                if (i < count && viewDepth < CascadeSplitFar[i]) { cascade = i; break; }
            }
            const float3 tints[4] = { float3(1.0, 0.3, 0.3), float3(0.3, 1.0, 0.3),
                                      float3(0.3, 0.5, 1.0), float3(1.0, 1.0, 0.3) };
            tint = tints[cascade];
        }
        return tint * (0.35 + 0.65 * luma);
    }
    if (mode == 6u) {
        // Light-count heatmap: 0 = deep blue, 8+ = red (the per-cluster budget scale).
        float t = saturate((float)lightCount / 8.0);
        return lerp(float3(0.05, 0.05, 0.6), float3(1.0, 0.1, 0.05), t);
    }
    if (mode == 7u) {
        // Overbright/invalid: magenta where the lit result is not plausibly finite
        // (NaN fails every comparison, so !(x < limit) catches NaN and +inf both).
        float m = max(lit.r, max(lit.g, lit.b));
        bool bad = !(m < 1e30) || !(m >= 0.0);
        float luma = saturate(dot(lit, float3(0.299, 0.587, 0.114)));
        return bad ? float3(1.0, 0.0, 1.0) : luma.xxx;
    }
    return lit;
}

#endif
