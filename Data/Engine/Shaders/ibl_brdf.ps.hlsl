// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

static const float PI = 3.14159265359;

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
float GeometrySchlickGGX(float ndv, float k) { return ndv / (ndv * (1.0 - k) + k); }
float GeometrySmith(float3 n, float3 v, float3 l, float k) {
    return GeometrySchlickGGX(max(dot(n, v), 0.0), k) * GeometrySchlickGGX(max(dot(n, l), 0.0), k);
}

float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    float ndv = max(uv.x, 1e-3);
    float roughness = uv.y;
    float3 V = float3(sqrt(1.0 - ndv * ndv), 0.0, ndv);
    float3 N = float3(0, 0, 1);
    float A = 0.0, B = 0.0;
    const uint SAMPLES = 1024u;
    float k = (roughness * roughness) / 2.0;   // IBL geometry term
    for (uint i = 0u; i < SAMPLES; ++i) {
        float2 xi = Hammersley(i, SAMPLES);
        float3 H = ImportanceSampleGGX(xi, N, roughness);
        float3 L = normalize(2.0 * dot(V, H) * H - V);
        float ndl = max(L.z, 0.0);
        float ndh = max(H.z, 0.0);
        float vdh = max(dot(V, H), 0.0);
        if (ndl > 0.0) {
            float G = GeometrySmith(N, V, L, k);
            float Gvis = (G * vdh) / max(ndh * ndv, 1e-4);
            float Fc = pow(1.0 - vdh, 5.0);
            A += (1.0 - Fc) * Gvis;
            B += Fc * Gvis;
        }
    }
    return float4(A / float(SAMPLES), B / float(SAMPLES), 0.0, 1.0);
}
