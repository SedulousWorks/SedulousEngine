// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#pragma pack_matrix(row_major)
Texture2D    SceneDepth : register(t0, space0);
SamplerState DepthSamp  : register(s0, space0);
Texture2D    DecalTex   : register(t0, space2);
SamplerState DecalSamp  : register(s0, space2);
cbuffer DecalUniforms : register(b0, space1) {
    row_major float4x4 World;
    row_major float4x4 InvWorld;
    row_major float4x4 InvViewProj;
    float4   Color;
    float4   Params;      // xy = 1/full-size, z = cos(fadeStart), w = cos(fadeEnd)
    float4   Flip;        // x = interpolant Y correction: +1 Vulkan (neg viewport), -1 Y-flip targets
};

float4 main(float4 pos : SV_Position, float2 ndc : TEXCOORD0) : SV_Target {
    // Sample the scene depth at THIS framebuffer pixel (SV_Position is the framebuffer position, so
    // pixel/size reads the texel the forward pass wrote here - no flip needed for a same-pixel read).
    float2 uv    = pos.xy * Params.xy;
    float  depth = SceneDepth.SampleLevel(DepthSamp, uv, 0).r;

    // Reconstruct world position from the interpolated emitted NDC - which is VIEWPORT-LOCAL,
    // exactly what the per-view InvViewProj expects (a full-target-uv reconstruction breaks
    // split-screen sub-rect views). On Y-flip targets the interpolant's pixel mapping mirrors,
    // so its Y is corrected by Flip.x (the SkyFlags.x convention: +1 Vulkan keeps it verbatim,
    // -1 on Y-flip targets un-mirrors). clip -> world via InvViewProj (same as SkyPass).
    ndc.y *= Flip.x;
    float4 h        = mul(float4(ndc, depth, 1.0), InvViewProj);
    float3 worldPos = h.xyz / h.w;

    // Into the decal's unit box; clip outside [-0.5, 0.5].
    float3 local = mul(float4(worldPos, 1.0), InvWorld).xyz;
    if (any(abs(local) > 0.5)) { discard; }

    // Decal UV from the box's local XY (project along local Z). Flip V for top-origin texture space.
    float2 decalUV = float2(local.x + 0.5, 0.5 - local.y);

    // Angle fade: receiver normal from world-pos screen derivatives vs the decal's projection axis
    // (local +Z in world = World row 2). Fade out where the surface faces away from the projection.
    float3 N        = normalize(cross(ddy(worldPos), ddx(worldPos)));
    float3 decalFwd = normalize(float3(World._m20, World._m21, World._m22));
    float  cosA     = dot(N, -decalFwd);
    float  fade     = smoothstep(Params.w, Params.z, cosA);

    float4 c = DecalTex.Sample(DecalSamp, decalUV) * Color;
    c.a *= fade;
    return c;
}
