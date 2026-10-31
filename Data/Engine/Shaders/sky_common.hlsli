// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

cbuffer Sky : register(b0, space0) {
    row_major float4x4 InvViewProj;    // inverse of this frame's UNJITTERED view-proj (stable sky ray under TAA)
    row_major float4x4 PrevViewProj;   // last frame's view-proj (motion vectors)
    float4 CamPosIntensity;   // xyz = camera world pos, w = sky-background display multiplier (not IBL)
    float4 SunDir;            // xyz = light direction, w = sun angular size (deg)
    float4 SunColor;          // rgb = sun color, w = sun intensity
    float4 Jitter;            // xy = this frame's NDC jitter, zw = last frame's
    float4 SkyFlags;          // x = scene-NDC Y sign (-1 on Y-flip targets: WebGPU today)
};
