// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "push_constant.hlsli"
#include "ao_common.hlsli"

Texture2D    DepthTex  : register(t0, space0);
Texture2D    NormalTex : register(t1, space0);
SamplerState PointSamp : register(s0, space0);
struct GtaoPush {
    row_major float4x4 InvProj;   // inverse projection: (ndc, depth) -> view space
    float2 TexelSize;             // 1 / size
    float  Radius;                // AO world-space radius
    float  Intensity;             // AO power
    float  ProjScaleY;            // projection(1,1): world radius -> screen (at unit view depth)
    int    FrameMod;              // per-frame noise rotation (unused while AO is static)
    int    DebugMode;             // 0=AO, 2=Nx, 3=Ny, 4=Nz, 5=viewZ, 6=rawDepth
    int    _pad;
};
PUSH_CONSTANT(GtaoPush, pc, space1);

static const float PI     = 3.14159265359;
static const float HALFPI = 1.57079632679;
static const int   SLICES = 3;
static const int   STEPS  = 6;

float3 ViewPos(float2 uv, float depth) {
    float2 ndc = float2(uv.x * 2.0 - 1.0, (1.0 - uv.y) * 2.0 - 1.0);
    float4 h = mul(float4(ndc, depth, 1.0), pc.InvProj);
    return h.xyz / h.w;
}
// Cosine-weighted arc integral for one horizon angle H, given the projected-normal angle n.
float ArcCosWeight(float H, float n) { return -cos(2.0 * H - n) + cos(n) + 2.0 * H * sin(n); }

float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    float depth = DepthTex.SampleLevel(PointSamp, uv, 0).r;
    if (depth >= 1.0) { return float4(1.0, 0, 0, 0); }   // background: no occlusion

    float3 P = ViewPos(uv, depth);
    float3 N = OctDecode(NormalTex.SampleLevel(PointSamp, uv, 0).rg);
    float3 V = normalize(-P);

    // uv-space march radius for this pixel's depth. NDC spans [-1,1] (length 2) -> uv [0,1] (length 1),
    // hence the /2. Clamp: at least one texel, at most a quarter screen.
    float screenR = pc.Radius * pc.ProjScaleY / (2.0 * max(-P.z, 1e-3));
    screenR = clamp(screenR, pc.TexelSize.y, 0.25);

    // Static interleaved-gradient noise (blur denoises it; static avoids temporal flicker).
    float noise      = frac(52.9829189 * frac(dot(pos.xy, float2(0.06711056, 0.00583715))));
    float noiseSlice = noise;
    float noiseStep  = frac(noise * 1.6180339887);

    const float invR2     = 2.0 / max(pc.Radius * pc.Radius, 1e-4);
    const float thickness = 0.1;

    float ao = 0.0;
    [unroll] for (int s = 0; s < SLICES; ++s) {
        float  phi  = (PI / float(SLICES)) * (float(s) + noiseSlice);
        float2 dir2 = float2(cos(phi), sin(phi));
        float3 sliceDir = normalize(float3(dir2, 0.0));

        float3 planeN = cross(sliceDir, V);
        float  planeLen = length(planeN);
        if (planeLen < 1e-4) { continue; }
        planeN /= planeLen;
        float3 T     = cross(V, planeN);
        float3 projN = N - planeN * dot(N, planeN);
        float  projLen = length(projN);
        if (projLen < 1e-4) { continue; }
        // Signed projected-normal angle; sign must match the reference (-sign(dot(projN,T))) or the arc
        // is corrupted on curved surfaces (where N varies) while looking fine on flat camera-facing faces.
        float  cosN = clamp(dot(projN, V) / projLen, -1.0, 1.0);
        float  n = -sign(dot(projN, T)) * acos(cosN);

        float2 hcos = float2(-1.0, -1.0);   // x = negative side, y = positive side
        [unroll] for (int t = 1; t <= STEPS; ++t) {
            float  r   = screenR * (float(t) - noiseStep) / float(STEPS);
            float2 off = dir2 * r;
            float2 up  = uv + off;
            if (all(up >= 0.0) && all(up <= 1.0)) {
                float3 ds = ViewPos(up, DepthTex.SampleLevel(PointSamp, up, 0).r) - P;
                float  d2 = dot(ds, ds);
                float  H  = dot(ds, V) * rsqrt(max(d2, 1e-12));
                float  fo = saturate(d2 * invR2);
                hcos.y = (H > hcos.y) ? lerp(H, hcos.y, fo) : lerp(H, hcos.y, thickness);
            }
            float2 un = uv - off;
            if (all(un >= 0.0) && all(un <= 1.0)) {
                float3 ds = ViewPos(un, DepthTex.SampleLevel(PointSamp, un, 0).r) - P;
                float  d2 = dot(ds, ds);
                float  H  = dot(ds, V) * rsqrt(max(d2, 1e-12));
                float  fo = saturate(d2 * invR2);
                hcos.x = (H > hcos.x) ? lerp(H, hcos.x, fo) : lerp(H, hcos.x, thickness);
            }
        }
        float h1 = acos(clamp(hcos.x, -1.0, 1.0));
        float h2 = acos(clamp(hcos.y, -1.0, 1.0));
        float H1 = n + max(-h1 - n, -HALFPI);
        float H2 = n + min( h2 - n,  HALFPI);
        ao += projLen * 0.25 * (ArcCosWeight(H1, n) + ArcCosWeight(H2, n));
    }
    ao = saturate(ao / float(SLICES));
    ao = pow(ao, max(pc.Intensity, 0.01));

    if (pc.DebugMode == 2) { return float4(N.x * 0.5 + 0.5, 0, 0, 0); }
    if (pc.DebugMode == 3) { return float4(N.y * 0.5 + 0.5, 0, 0, 0); }
    if (pc.DebugMode == 4) { return float4(N.z * 0.5 + 0.5, 0, 0, 0); }
    if (pc.DebugMode == 5) { return float4(saturate(-P.z / 50.0), 0, 0, 0); }
    if (pc.DebugMode == 6) { return float4(saturate((depth - 0.8) * 5.0), 0, 0, 0); }
    return float4(ao, 0, 0, 0);
}
