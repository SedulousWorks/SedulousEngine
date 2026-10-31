// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "push_constant.hlsli"
struct Push { int FaceIndex; float Roughness; float2 Pad; };
PUSH_CONSTANT(Push, pc, space1);
// Single-cube view of the prefiltered cube-ARRAY (this probe's 6 faces). A CUBE-ARRAY type is
// required: DX12's TEXTURECUBE SRV cannot address a non-zero first face (it always views cube 0),
// so the bound view selects the probe and the shader samples cube 0 of it.
TextureCubeArray<float4> Src  : register(t0, space0);
SamplerState             Samp : register(s0, space0);
static const float PI = 3.14159265359;
float3 DirForFace(int face, float2 uv) {
    float2 t = uv * 2.0 - 1.0;
    float3 d;
    if      (face == 0) d = float3( 1.0,  t.y, -t.x);
    else if (face == 1) d = float3(-1.0,  t.y,  t.x);
    else if (face == 2) d = float3( t.x,  1.0, -t.y);
    else if (face == 3) d = float3( t.x, -1.0,  t.y);
    else if (face == 4) d = float3( t.x,  t.y,  1.0);
    else                d = float3(-t.x,  t.y, -1.0);
    return normalize(d);
}
float RadicalInverse_VdC(uint bits) {
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    return float(bits) * 2.3283064365386963e-10;
}
float2 Hammersley(uint i, uint n) { return float2(float(i) / float(n), RadicalInverse_VdC(i)); }
float3 ImportanceSampleGGX(float2 xi, float3 n, float roughness) {
    float a = roughness * roughness;
    float phi = 2.0 * PI * xi.x;
    float cosT = sqrt((1.0 - xi.y) / (1.0 + (a * a - 1.0) * xi.y));
    float sinT = sqrt(1.0 - cosT * cosT);
    float3 h = float3(cos(phi) * sinT, sin(phi) * sinT, cosT);
    float3 up = abs(n.z) < 0.999 ? float3(0, 0, 1) : float3(1, 0, 0);
    float3 tx = normalize(cross(up, n));
    float3 ty = cross(n, tx);
    return normalize(tx * h.x + ty * h.y + n * h.z);
}
float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target0 {
    float3 N = DirForFace(pc.FaceIndex, uv);
    float3 V = N;
    const uint SAMPLES = 128u;   // per-probe, may run every frame (Realtime) -> fewer than IBL's 1024
    float3 color = 0.0; float weight = 0.0;
    for (uint i = 0u; i < SAMPLES; ++i) {
        float2 xi = Hammersley(i, SAMPLES);
        float3 H  = ImportanceSampleGGX(xi, N, pc.Roughness);
        float3 L  = normalize(2.0 * dot(V, H) * H - V);
        float  ndl = dot(N, L);
        if (ndl > 0.0) {
            float3 s = Src.SampleLevel(Samp, float4(L, 0.0), 0.0).rgb;
            // Karis firefly reduction: down-weight bright samples (tone weight) so sparse importance-sample
            // hits on tiny bright sources (moving point lights in the low-res capture) don't alias/flicker.
            float fw = ndl / (1.0 + dot(s, float3(0.2126, 0.7152, 0.0722)));
            color += s * fw; weight += fw;
        }
    }
    return float4(color / max(weight, 1e-4), 1.0);
}
