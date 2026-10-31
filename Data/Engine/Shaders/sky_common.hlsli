// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

cbuffer Sky : register(b0, space0) {
    row_major float4x4 InvViewProj;    // inverse of this frame's UNJITTERED view-proj (stable sky ray under TAA)
    row_major float4x4 PrevViewProj;   // last frame's view-proj (motion vectors)
    float3 CameraPos;             // camera world position
    float  BackgroundIntensity;   // the sky background's display multiplier (not IBL)
    float3 SunDirection;          // the light's direction
    float  SunAngularSizeDegrees;
    float3 SunColor;
    float  SunIntensity;
    float2 Jitter;            // this frame's NDC jitter
    float2 PrevJitter;        // last frame's NDC jitter (unjitters the reprojection)
    float  SceneYSign;        // the scene NDC's Y sign: -1 on Y-flip targets (WebGPU today), +1 on Vulkan
    float  _skyPad0;
    float  _skyPad1;
    float  _skyPad2;
};
