// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The forward pixel stage's contract, beside the lighting: the screen-door fade (DITHER), and
// under GBUFFER the five targets the post stack reads (colour, view normal, motion vector,
// roughness/metallic, albedo). The engine's forward pass writes them so, and so must a custom
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

#endif
