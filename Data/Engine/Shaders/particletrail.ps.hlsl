// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

Texture2D    ParticleTexture : register(t0, space1);
SamplerState ParticleSampler : register(s0, space1);
float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0, float4 col : COLOR0) : SV_Target {
    return ParticleTexture.Sample(ParticleSampler, uv) * col;
}
