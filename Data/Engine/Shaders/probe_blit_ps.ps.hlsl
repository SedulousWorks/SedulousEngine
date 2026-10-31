// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

Texture2DArray<float4> SrcFace : register(t0, space0);
SamplerState           Samp    : register(s0, space0);
float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target0 {
    // flip-u corrects the RH-LookAt mirror; flip-v corrects the vertical inversion from the capture +
    // blit both passing through the negative viewport. (Retested after fixing the sky-slot collision that
    // had scrambled the earlier read.)
    return SrcFace.SampleLevel(Samp, float3(1.0 - uv.x, 1.0 - uv.y, 0.0), 0.0);
}
