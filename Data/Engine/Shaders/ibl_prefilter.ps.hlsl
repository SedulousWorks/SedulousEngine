// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "ibl_common.hlsli"

TextureCube<float4> EnvMap : register(t0, space0);
SamplerState        EnvSamp : register(s0, space0);

static const float PI = 3.14159265359;
static const float ENV_RES = 256.0;   // env cube face resolution (mip 0)

float DistributionGGX(float ndh, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float d = (ndh * ndh) * (a2 - 1.0) + 1.0;
    return a2 / max(PI * d * d, 1e-7);
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

float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    float3 N = DirForFace(pc.FaceIndex, uv);
    float3 V = N;
    const uint SAMPLES = 1024u;
    float3 color = 0.0;
    float  weight = 0.0;
    for (uint i = 0u; i < SAMPLES; ++i) {
        float2 xi = Hammersley(i, SAMPLES);
        float3 H = ImportanceSampleGGX(xi, N, pc.Roughness);
        float3 L = normalize(2.0 * dot(V, H) * H - V);
        float ndl = dot(N, L);
        if (ndl > 0.0) {
            // Karis: pick the env mip whose texel solid angle matches this sample's solid angle, so
            // sparse high-roughness samples average many source texels instead of aliasing bright ones.
            float ndh = max(dot(N, H), 0.0);   // N == V, so NdotH == HdotV
            float D   = DistributionGGX(ndh, pc.Roughness);
            float pdf = (D * ndh / (4.0 * ndh)) + 1e-4;
            float saTexel  = 4.0 * PI / (6.0 * ENV_RES * ENV_RES);
            float saSample = 1.0 / (float(SAMPLES) * pdf + 1e-4);
            float mip = (pc.Roughness < 1e-3) ? 0.0 : max(0.5 * log2(saSample / saTexel), 0.0);
            color += EnvMap.SampleLevel(EnvSamp, L, mip).rgb * ndl;
            weight += ndl;
        }
    }
    return float4(color / max(weight, 1e-4), 1.0);
}
