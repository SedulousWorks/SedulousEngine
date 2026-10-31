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
    float2 Jitter;                     // this frame's NDC jitter (TAA)
    float2 PrevJitter;                 // last frame's NDC jitter (unjitters the motion vectors)
    uint   ProbeBase;                  // this view's scene's first record in Probes[] (scenes' records are concatenated)
    uint   ProbeCount;                 // its reflection probes (0 = none: the global IBL alone)
    uint   _probePad0;
    uint   _probePad1;
    float  ShadowFarFade;              // the CSM's far fade width, in world units
    float  ShadowUvYSign;              // the shadow map's uv Y sign: -1 on Vulkan (negative viewport), +1 on Y-flip targets
    float  _shadowPad0;
    float  _shadowPad1;
    uint   DebugMode;                  // the semantic debug view (ViewDebugSemantic; 0 = off)
    uint   _debugPad0;
    uint   _debugPad1;
    uint   _debugPad2;
    float  IblDiffuse;                 // the sky-lighting dimmer (diffuse image lighting)
    float  IblSpecular;                // the sky-reflection dimmer (specular image lighting)
    float  SceneTime;                  // the view's scene clock (s): the WIND sway, a surface's Time()
    float  PrevSceneTime;              // last frame's (the previous position, for motion vectors)
};

// Whether this view is orthographic: its view-projection's w column is exactly zero then (w stays 1)
// and never for a perspective one (w is the view depth); neither projection's jitter touches it.
bool ViewIsOrthographic() {
    return ViewProj[0][3] == 0.0 && ViewProj[1][3] == 0.0 && ViewProj[2][3] == 0.0;
}

// The unit direction from a world point toward the viewer: to the camera under perspective; under
// orthographic every view ray is parallel, so straight back along the view.
float3 ViewDirToCamera(float3 worldPos) {
    return ViewIsOrthographic() ? normalize(float3(View[0][2], View[1][2], View[2][2]))
                                : normalize(CameraPos - worldPos);
}

// A point toward the viewer for code that takes an eye position and aims at it (a surface's
// viewDir): the camera itself under perspective; under orthographic, a metre back along the view
// from the point, so the aim is the parallel view direction.
float3 ViewEyeFor(float3 worldPos) {
    return ViewIsOrthographic() ? worldPos + ViewDirToCamera(worldPos) : CameraPos;
}

#endif
