// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "ibl_common.hlsli"

TextureCube  SrcCube  : register(t0, space0);
SamplerState SrcSamp  : register(s0, space0);
float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    float3 dir = DirForFace(pc.FaceIndex, uv);
    float rot = pc.Zenith.a;   // sky rotation yaw (see the equirect pass)
    float cr = cos(rot), sr = sin(rot);
    dir = float3(cr * dir.x + sr * dir.z, dir.y, -sr * dir.x + cr * dir.z);
    return float4(SrcCube.SampleLevel(SrcSamp, dir, 0.0).rgb * max(pc.SkyIntensity, 0.0), 1.0);
}
