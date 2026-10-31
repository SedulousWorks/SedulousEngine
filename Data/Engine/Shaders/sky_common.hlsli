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
    float4 Jitter;            // xy = this frame's NDC jitter, zw = last frame's
    float4 SkyFlags;          // x = scene-NDC Y sign (-1 on Y-flip targets: WebGPU today)
};
