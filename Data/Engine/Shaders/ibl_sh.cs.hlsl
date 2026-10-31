// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

TextureCube<float4> EnvMap : register(t0, space0);
SamplerState        EnvSamp : register(s0, space0);
RWStructuredBuffer<float4> ShOut : register(u0, space0);

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

[numthreads(1, 1, 1)]
void main(uint3 dtid : SV_DispatchThreadID) {
    float3 sh[9];
    for (int i = 0; i < 9; ++i) sh[i] = 0.0;
    float wsum = 0.0;
    const int N = 32;   // per-face resolution for the projection
    for (int face = 0; face < 6; ++face) {
        for (int y = 0; y < N; ++y) {
            for (int x = 0; x < N; ++x) {
                float2 uv = (float2(x, y) + 0.5) / float(N);
                float3 dir = DirForFace(face, uv);
                // Differential solid angle for this cube texel.
                float2 t = uv * 2.0 - 1.0;
                float tmp = 1.0 + t.x * t.x + t.y * t.y;
                float w = 4.0 / (sqrt(tmp) * tmp) / float(N * N);
                float3 c = EnvMap.SampleLevel(EnvSamp, dir, 0.0).rgb * w;
                wsum += w;
                // Real SH basis (l=0..2).
                sh[0] += c * 0.282095;
                sh[1] += c * 0.488603 * dir.y;
                sh[2] += c * 0.488603 * dir.z;
                sh[3] += c * 0.488603 * dir.x;
                sh[4] += c * 1.092548 * dir.x * dir.y;
                sh[5] += c * 1.092548 * dir.y * dir.z;
                sh[6] += c * 0.315392 * (3.0 * dir.z * dir.z - 1.0);
                sh[7] += c * 1.092548 * dir.x * dir.z;
                sh[8] += c * 0.546274 * (dir.x * dir.x - dir.y * dir.y);
            }
        }
    }
    float norm = (4.0 * PI) / max(wsum, 1e-4);
    for (int j = 0; j < 9; ++j) ShOut[j] = float4(sh[j] * norm, 0.0);
}
