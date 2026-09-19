// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "sky_common.hlsli"
#include "depth.hlsli"

struct VSOut { float4 pos : SV_Position; float3 dir : TEXCOORD0; float2 ndc : TEXCOORD1; };
VSOut main(uint vid : SV_VertexID) {
    float2 uv  = float2((vid << 1) & 2, vid & 2);
    float2 ndc = uv * 2.0 - 1.0;
    VSOut o;
    o.pos = float4(ndc, kDepthFar, 1.0);                  // AT the far plane: only a cleared pixel passes
    // Reconstruct the world ray for the pixel this fragment LANDS ON. On Vulkan (negative
    // viewport) the emitted NDC matches the scene geometry's NDC at that pixel; on Y-flip
    // targets (no negative viewport) the geometry occupying the same pixel has MIRRORED
    // clip y, so negate NDC y BEFORE unprojecting (SkyFlags.x = -1 there, +1 on Vulkan).
    // Flipping in NDC (not the world ray) keeps the ray correct under camera pitch/roll
    // and keeps the reprojection below in one consistent scene-NDC convention.
    float2 sceneNdc = float2(ndc.x, ndc.y * SkyFlags.x);
    o.ndc = sceneNdc; // scene-convention NDC: the PS velocity reprojection compares like with like
    float4 world = mul(float4(sceneNdc, kDepthFar, 1.0), InvViewProj);  // clip -> world, on the far plane
    o.dir = world.xyz / world.w - CamPosIntensity.xyz;
    return o;
}
