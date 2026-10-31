// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "ibl_common.hlsli"

Texture2D    EquirectMap  : register(t0, space0);
SamplerState EquirectSamp : register(s0, space0);
static const float PI2 = 3.14159265359;
float2 DirToEquirect(float3 d) {
    float phi   = atan2(d.z, d.x);
    float theta = asin(clamp(d.y, -1.0, 1.0));
    return float2(phi / (2.0 * PI2) + 0.5, 1.0 - (theta / PI2 + 0.5));
}
float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    float3 dir = DirForFace(pc.FaceIndex, uv);
    // Yaw by the sky rotation (Zenith.a) - this and the cubemap pass are where the user's
    // rotation slider actually lands (the procedural gradient is rotation-invariant).
    float rot = pc.Zenith.a;
    float cr = cos(rot), sr = sin(rot);
    dir = float3(cr * dir.x + sr * dir.z, dir.y, -sr * dir.x + cr * dir.z);
    return float4(EquirectMap.SampleLevel(EquirectSamp, DirToEquirect(dir), 0.0).rgb * max(pc.SkyIntensity, 0.0), 1.0);
}
