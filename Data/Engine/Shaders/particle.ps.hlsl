// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#pragma pack_matrix(row_major)
cbuffer ParticleView : register(b0, space0) {
    float4x4 ViewProj;
    float4x4 View;
    // The projection terms that turn a sampled NDC depth back into view depth (soft particles).
    float    ProjZScale;    // Proj[2][2]
    float    ProjZOffset;   // Proj[3][2]
    float    ProjWScale;    // Proj[2][3]: -1 perspective, 0 orthographic
    float    _particleViewPad0;
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
        // Positive view-space depth. Proj[2][3] is -1 for a perspective projection and 0 for an
        // orthographic one, whose depth is linear: d = Proj[2][2] * z + Proj[3][2].
        float sceneLin = (ProjWScale == 0.0) ? (ProjZOffset - d) / ProjZScale
                                             : -ProjZOffset / (d * ProjWScale - ProjZScale);
        c.a *= saturate((sceneLin - linZ) / max(softDist, 1e-3));
    }
    return c;
}
