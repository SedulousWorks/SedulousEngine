// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The frame's View constants (set 0, b0), shared by every forward-family stage: the forward and
// unlit passes and a custom shader. Mirrors the CPU view block; change them together.
#ifndef VIEW_HLSLI
#define VIEW_HLSLI

#define CASCADE_COUNT 4
cbuffer View : register(b0, space0) {
    row_major float4x4 ViewProj;   // Matrices are row-major; annotate so HLSL reads them right.
    row_major float4x4 View;       // for view-space depth (cluster lookup + CSM cascade select, PS only)
    row_major float4x4 CascadeViewProj[CASCADE_COUNT];   // CSM: world -> each cascade's light clip
    float3 CameraPos; float LightCount;
    uint   LightOffset; int ClusterVpX; int ClusterVpY; float IBLMaxLod;   // IBLMaxLod < 0 -> no IBL (flat ambient)
    uint   ClusterGridX; uint ClusterGridY; uint ClusterSliceCount; uint ClusterTileSize;
    float  ClusterNear;  float ClusterFar;  float ClusterLogScale;  float ClusterLogBias;
    float3 Ambient; float ShadowCascadeCount;          // 0 -> no shadow
    float4 CascadeSplitFar;        // view-space far depth of each cascade (cascade selection)
    float4 CascadeTexelSize;       // world units per shadow texel, per cascade (normal-offset bias)
    float  ShadowNormalBias; float ShadowDepthBias; float CascadeLayerBase; uint LocalShadowBase;
    row_major float4x4 PrevViewProj;   // last frame's world->clip (motion vectors)
    float4 Jitter;                     // xy = this frame's NDC jitter, zw = last frame's (TAA)
    float4 ProbeCenter;                // xyz = reflection-probe center (world), w = probe count (0 = none)
    float4 ProbeBoxMin;                // xyz = probe box min corner,  w = probe cube slice (index into ProbeArray)
    float4 ProbeBoxMax;                // xyz = probe box max corner,  w = probe intensity
    float4 ShadowParams;               // x = CSM far-fade width in WORLD UNITS, y = clip-space Y sign, zw = instance fade start/end (an instanced set's private view slot; 0 = none)
    float4 DebugParams;                // x = semantic debug-view mode (0 = off); yzw spare
    float4 IblParams;                  // x = IBL diffuse intensity, y = IBL specular intensity, z = time (s), w = last frame's time
};

#endif
