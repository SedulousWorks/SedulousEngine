// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "push_constant.hlsli"
#include "depth.hlsli"
#include "ao_common.hlsli"

Texture2D    DepthTex  : register(t0, space0);
Texture2D    NormalTex : register(t1, space0);
SamplerState PointSamp : register(s0, space0);
struct SsaoPush {
    row_major float4x4 InvProj;   // (ndc, depth) -> view space
    float2 TexelSize;
    float2 Jitter;                // this frame's projection jitter (proj(2,0), proj(2,1)) in NDC
    float  ProjXX;                // projection(0,0): view -> ndc.x
    float  ProjYY;                // projection(1,1): view -> ndc.y
    float  Radius;
    float  Intensity;
    float  Bias;
    int    SampleCount;
    int    DebugMode;
};
PUSH_CONSTANT(SsaoPush, pc, space1);

float3 ViewPos(float2 uv, float depth) {
    float2 ndc = float2(uv.x * 2.0 - 1.0, (1.0 - uv.y) * 2.0 - 1.0);
    float4 h = mul(float4(ndc, depth, 1.0), pc.InvProj);
    return h.xyz / h.w;
}
// View-space position -> top-origin uv (inverse of ViewPos's uv->ndc: uv.y = (1-ndc.y)/2). The jitter
// (in the projection's z-row, not the diagonal ProjXX/YY) must be included or the back-projected UV won't
// match the jittered depth buffer we sample -> per-frame occlusion oscillation (flicker under TAA).
float2 ViewToUv(float3 vp) {
    // Full jittered ndc = diagonal ndc - jitter (the jitter lives in proj's z-row: ndc shifts by -jitter).
    float2 ndc = float2(vp.x * pc.ProjXX, vp.y * pc.ProjYY) / max(-vp.z, 1e-4) - pc.Jitter;
    return float2(ndc.x * 0.5 + 0.5, 0.5 - 0.5 * ndc.y);
}
static const float3 KERNEL[16] = {
    float3( 0.5381, 0.1856,-0.4319), float3( 0.1379, 0.2486, 0.4430),
    float3( 0.3371, 0.5679,-0.0057), float3(-0.6999,-0.0451,-0.0019),
    float3( 0.0689,-0.1598,-0.8547), float3( 0.0560, 0.0069,-0.1843),
    float3(-0.0146, 0.1402, 0.0762), float3( 0.0100,-0.1924,-0.0344),
    float3(-0.3577,-0.5301,-0.4358), float3(-0.3169, 0.1063, 0.0158),
    float3( 0.0103,-0.5869, 0.0046), float3(-0.0897,-0.4940, 0.3287),
    float3( 0.7119,-0.0154,-0.0918), float3(-0.0533, 0.0596,-0.5411),
    float3( 0.0352,-0.0631, 0.5460), float3(-0.4776, 0.2847,-0.0271)
};

float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    float depth = DepthTex.SampleLevel(PointSamp, uv, 0).r;
    if (IsBackgroundDepth(depth)) { return float4(1.0, 0, 0, 0); }   // background: no occlusion

    float3 P = ViewPos(uv, depth);
    float3 N = OctDecode(NormalTex.SampleLevel(PointSamp, uv, 0).rg);

    // Per-pixel rotation + TBN for hemisphere orientation. Interleaved-gradient noise (not white-noise
    // hash): it denoises cleanly under the bilateral blur + TAA, whereas a white-noise pattern swims under
    // motion and flickers when the AO is baked into color pre-TAA.
    float ign = frac(52.9829189 * frac(dot(pos.xy, float2(0.06711056, 0.00583715))));
    float a = ign * 6.2831853;
    float ca = cos(a), sa = sin(a);
    float3 tangent = abs(N.z) < 0.999 ? float3(0, 0, 1) : float3(1, 0, 0);
    tangent = normalize(tangent - N * dot(tangent, N));
    float3 bitangent = cross(N, tangent);

    int   count = min(pc.SampleCount, 16);
    float occlusion = 0.0; int valid = 0;
    [loop] for (int i = 0; i < count; ++i) {
        float3 k = KERNEL[i];
        float3 rot = float3(k.x * ca - k.y * sa, k.x * sa + k.y * ca, k.z);   // rotate in tangent plane
        float3 off = tangent * rot.x + bitangent * rot.y + N * rot.z;         // orient to hemisphere
        float  scale = (float(i) + 1.0) / float(count);
        scale = lerp(0.1, 1.0, scale * scale);                               // cluster samples near P
        float3 samplePos = P + off * pc.Radius * scale;

        float2 sUv = ViewToUv(samplePos);
        if (any(sUv < 0.0) || any(sUv > 1.0)) { continue; }
        float  sampleZ = ViewPos(sUv, DepthTex.SampleLevel(PointSamp, sUv, 0).r).z;
        float  diff = sampleZ - P.z;   // RH view space: an occluder (closer) is less negative -> larger
        // Smooth occlusion ramp, NOT a hard step: under TAA the depth is jittered sub-pixel each frame, so
        // a binary test flips samples on/off between frames -> shimmer. A soft band makes SSAO continuous
        // in its inputs (like GTAO's arc integral), so TAA can stabilize it.
        float  band = max(pc.Radius * 0.15, 1e-3);
        float  occluded = smoothstep(pc.Bias, pc.Bias + band, diff);
        float  rangeCheck = smoothstep(0.0, 1.0, pc.Radius / (abs(diff) + 0.001));
        if (abs(diff) > pc.Radius * 2.0) { rangeCheck = 0.0; }               // reject far leaks
        occlusion += occluded * rangeCheck;
        valid++;
    }
    float ao = 1.0;
    if (valid > 0) { ao = 1.0 - occlusion / float(valid); ao = pow(saturate(ao), max(pc.Intensity, 0.01)); }

    if (pc.DebugMode == 2) { return float4(N.x * 0.5 + 0.5, 0, 0, 0); }
    if (pc.DebugMode == 3) { return float4(N.y * 0.5 + 0.5, 0, 0, 0); }
    if (pc.DebugMode == 4) { return float4(N.z * 0.5 + 0.5, 0, 0, 0); }
    if (pc.DebugMode == 5) { return float4(saturate(-P.z / 50.0), 0, 0, 0); }
    if (pc.DebugMode == 6) { return float4(saturate((depth - 0.8) * 5.0), 0, 0, 0); }
    return float4(ao, 0, 0, 0);
}
