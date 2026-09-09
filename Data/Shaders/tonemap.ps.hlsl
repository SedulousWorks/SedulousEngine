// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "push_constant.hlsli"
Texture2D<float4> Hdr       : register(t0, space0);
Texture2D<float4> Bloom     : register(t1, space0);
Texture2D<float4> Ao        : register(t2, space0);
Texture2D<float4> AutoLum   : register(t3, space0); // 1x1 adapted luminance (auto-exposure)
Texture2D<float4> GradeLut  : register(t4, space0); // 2D strip LUT (width = size*size, height = size)
SamplerState      BloomSamp : register(s0, space0);
// UvScale/UvOffset map the fullscreen [0,1] uv to this view's sub-rect of the (full-size) HDR/bloom
// transients - so split-screen views resolve their own region instead of the whole target.
// AoStrength lerps the AO factor in (0 = GTAO off).
struct TonemapPush { float Exposure; float BloomIntensity; float2 UvScale; float2 UvOffset; float AoStrength; float DebugShowAo; float Operator; float FlipSceneY;
                     float AutoExposure; float AutoKey; float AutoMin; float AutoMax; float GradeIntensity; float LutSize; };
PUSH_CONSTANT(TonemapPush, pc, space1);

// Linear -> sRGB display encode (the OETF the CM1a "clamp" operator needs before writing the
// UNORM target; the AgX path bakes its own display encoding in).
float3 linearToSrgb(float3 c) {
    c = saturate(c);
    float3 lo = c * 12.92;
    float3 hi = 1.055 * pow(c, 1.0 / 2.4) - 0.055;
    return lerp(hi, lo, step(c, 0.0031308));
}

// 6th-order polynomial fit of the AgX log->display sigmoid.
float3 agxContrast(float3 x) {
    float3 x2 = x * x;
    float3 x4 = x2 * x2;
    return  15.5 * x4 * x2 - 40.14 * x4 * x + 31.96 * x4
          - 6.868 * x2 * x + 0.4298 * x2 + 0.1191 * x - 0.00232;
}

// The "punchy" AgX look (Blender's default): a contrast power + saturation boost around luma.
// Neutral base AgX is intentionally flat; this is what gives the expected filmic punch.
float3 agxLook(float3 val) {
    const float3 lw = float3(0.2126, 0.7152, 0.0722);
    float luma = dot(val, lw);
    val = pow(max(val, 0.0), float3(1.35, 1.35, 1.35));   // contrast (deeper shadows)
    return luma + 1.4 * (val - luma);                     // saturation
}

// Display-referred color grading via a 2D strip LUT (the standard Photoshop-authored neutral
// strip: width = size*size, height = size; blue selects the slice). Trilinear = two slice
// samples + a lerp. LutSize = 0 disables; GradeIntensity mixes the graded result in.
float3 applyGrade(float3 c) {
    if (pc.LutSize < 1.5) { return c; }
    float size = pc.LutSize;
    c = saturate(c);
    float slice = c.b * (size - 1.0);
    float sliceLo = floor(slice);
    float sliceFrac = slice - sliceLo;
    float texelW = 1.0 / (size * size);
    float u = (c.r * (size - 1.0) + 0.5) * texelW;
    float v = (c.g * (size - 1.0) + 0.5) / size;
    float uLo = u + sliceLo * (1.0 / size);
    float uHi = u + min(sliceLo + 1.0, size - 1.0) * (1.0 / size);
    float3 lo = GradeLut.SampleLevel(BloomSamp, float2(uLo, v), 0).rgb;
    float3 hi = GradeLut.SampleLevel(BloomSamp, float2(uHi, v), 0).rgb;
    return lerp(c, lerp(lo, hi, sliceFrac), saturate(pc.GradeIntensity));
}

float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    // Sample HDR + bloom with the SAME (top-origin) uv, mapped to this view's sub-rect. Both via Sample
    // (Sedulous-style - mixing Load(pos) with Sample(uv) is what caused the mirrored bloom ghost).
    // FlipSceneY: on Y-flip backends (WebGPU) the scene HDR arrives MIRRORED unless the TAA
    // resolve ran (its NDC-based uv reconstruction un-mirrors it). When TAA is off, tonemap -
    // the first post pass - un-mirrors instead, so the LDR intermediate and everything after
    // (post-tonemap UI, FXAA, the final target) are upright. Flip the LOCAL uv before the
    // sub-rect mapping so split-screen views flip within their own region. Bloom/AO were
    // built from the same mirrored scene, so the shared flipped uv keeps all three aligned.
    float2 local = uv;
    if (pc.FlipSceneY > 0.5) { local.y = 1.0 - local.y; }
    float2 st = pc.UvOffset + local * pc.UvScale;
    // Debug: show the GTAO buffer (or a debug channel it wrote) straight to screen, no tonemap.
    if (pc.DebugShowAo > 0.5) { return float4(Ao.SampleLevel(BloomSamp, st, 0).rrr, 1.0); }
    float3 c = max(Hdr.SampleLevel(BloomSamp, st, 0).rgb, 0.0);
    float ao = lerp(1.0, Ao.SampleLevel(BloomSamp, st, 0).r, saturate(pc.AoStrength));   // GTAO
    c *= ao;                                                                       // occlude before adding bloom
    c += Bloom.SampleLevel(BloomSamp, st, 0).rgb * max(pc.BloomIntensity, 0.0);   // additive bloom (linear HDR)
    float exposure = max(pc.Exposure, 0.0);
    if (pc.AutoExposure > 0.5) {
        // Adapted scene luminance -> a key/avg multiplier, clamped to the authored EV window.
        float avg = max(AutoLum.SampleLevel(BloomSamp, float2(0.5, 0.5), 0).r, 1e-4);
        exposure *= clamp(pc.AutoKey / avg, pc.AutoMin, pc.AutoMax);
    }
    c *= exposure;   // linear exposure multiplier (scene EV x adaptation)

    // CM1a: a trivial clamp operator (saturate) + the sRGB display OETF. AgX (below) is the default.
    if (pc.Operator < 0.5) { return float4(applyGrade(linearToSrgb(c)), 1.0); }

    const float3x3 agxInset = float3x3(
        0.842479062253094, 0.0423282422610123, 0.0423756549057051,
        0.0784335999999992, 0.878468636469772, 0.0784336,
        0.0792237451477643, 0.0791661274605434, 0.879142973793104);
    const float3x3 agxOutset = float3x3(
        1.19687900512017,   -0.0528968517574562, -0.0529716355144438,
        -0.0980208811401368, 1.15190312990417,   -0.0980434501171241,
        -0.0990297440797205, -0.0989611768448433, 1.15107367264116);
    const float minEv = -12.47393;
    const float maxEv =  4.026069;

    float3 v = mul(agxInset, c);
    v = clamp(log2(max(v, 1e-10)), minEv, maxEv);
    v = (v - minEv) / (maxEv - minEv);     // normalize to [0,1]
    v = agxContrast(v);                    // sigmoid (output is display-encoded)
    v = agxLook(v);                        // punchy look (contrast + saturation)
    v = mul(agxOutset, v);
    return float4(applyGrade(saturate(v)), 1.0); // straight to the UNORM display target
}
