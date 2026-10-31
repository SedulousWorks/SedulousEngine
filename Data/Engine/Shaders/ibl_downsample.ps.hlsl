// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "ibl_common.hlsli"

TextureCube  SrcCube : register(t0, space0);
SamplerState SrcSamp : register(s0, space0);
float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    float3 dir = DirForFace(pc.FaceIndex, uv);
    return float4(SrcCube.SampleLevel(SrcSamp, dir, 0.0).rgb, 1.0);
}
