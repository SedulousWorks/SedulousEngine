// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#pragma pack_matrix(row_major)
cbuffer ParticleView : register(b0, space0) {
    float4x4 ViewProj;
    float4x4 View;
    float4   DepthParams;   // x=Proj[2][2], y=Proj[3][2], z=Proj[2][3], w=soft fade distance
};
Texture2D    ParticleTexture : register(t0, space1);
SamplerState ParticleSampler : register(s0, space1);
Texture2D    SceneDepth      : register(t0, space2);   // opaque depth (read-only, sampleable)
float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0, float4 col : COLOR0, float linZ : TEXCOORD1, float softDist : TEXCOORD2) : SV_Target {
    float4 c = ParticleTexture.Sample(ParticleSampler, uv) * col;
    // Soft particle (per-system, softDist>0): fade where this billboard fragment approaches the opaque
    // surface behind it. Sample the scene depth, reconstruct its view-space depth, compare to the fragment's.
    if (softDist > 0.0) {
        float d = SceneDepth.Load(int3(int2(pos.xy), 0)).r;
        float sceneLin = -DepthParams.y / (d * DepthParams.z - DepthParams.x);   // positive view-space depth
        c.a *= saturate((sceneLin - linZ) / max(softDist, 1e-3));
    }
    return c;
}
