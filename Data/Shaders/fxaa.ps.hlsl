// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#include "push_constant.hlsli"
Texture2D    SceneColor : register(t0, space0);
SamplerState LinearSamp : register(s0, space0);
struct FxaaPush {
    float2 TexelSize;         // 1 / full target size
    float2 UvScale;           // fullscreen uv -> view sub-rect
    float2 UvOffset;
    float  SubpixelQuality;   // 0.75 default
    float  EdgeThreshold;     // 0.166 default
    float  EdgeThresholdMin;  // 0.0312 default (skip dark/flat)
    float  _pad;
};
PUSH_CONSTANT(FxaaPush, pc, space1);

float Luma(float3 c) { return dot(c, float3(0.299, 0.587, 0.114)); }
float3 Fetch(float2 uv) { return SceneColor.SampleLevel(LinearSamp, uv, 0).rgb; }

float4 main(float4 pos : SV_Position, float2 rawUv : TEXCOORD0) : SV_Target {
    float2 ts = pc.TexelSize;
    float2 uv = pc.UvOffset + rawUv * pc.UvScale;   // this view's sub-rect

    float3 cC = Fetch(uv);
    float lC = Luma(cC);
    float lN = Luma(Fetch(uv + float2(0.0, -ts.y)));
    float lS = Luma(Fetch(uv + float2(0.0,  ts.y)));
    float lE = Luma(Fetch(uv + float2( ts.x, 0.0)));
    float lW = Luma(Fetch(uv + float2(-ts.x, 0.0)));

    float lMin = min(lC, min(min(lN, lS), min(lE, lW)));
    float lMax = max(lC, max(max(lN, lS), max(lE, lW)));
    float range = lMax - lMin;
    if (range < max(pc.EdgeThresholdMin, lMax * pc.EdgeThreshold)) { return float4(cC, 1.0); }

    float lNW = Luma(Fetch(uv + float2(-ts.x, -ts.y)));
    float lNE = Luma(Fetch(uv + float2( ts.x, -ts.y)));
    float lSW = Luma(Fetch(uv + float2(-ts.x,  ts.y)));
    float lSE = Luma(Fetch(uv + float2( ts.x,  ts.y)));

    // Sub-pixel aliasing amount.
    float lAvg = (lN + lS + lE + lW) * 0.25;
    float sub = saturate(abs(lAvg - lC) / range);
    sub = smoothstep(0.0, 1.0, sub); sub = sub * sub * pc.SubpixelQuality;

    // Edge orientation.
    float edgeH = abs(lNW + lNE - 2.0 * lN) + abs(lW + lE - 2.0 * lC) * 2.0 + abs(lSW + lSE - 2.0 * lS);
    float edgeV = abs(lNW + lSW - 2.0 * lW) + abs(lN + lS - 2.0 * lC) * 2.0 + abs(lNE + lSE - 2.0 * lE);
    bool horz = (edgeH >= edgeV);

    float stepLen = horz ? ts.y : ts.x;
    float lPos = horz ? lS : lE;
    float lNeg = horz ? lN : lW;
    float gPos = abs(lPos - lC);
    float gNeg = abs(lNeg - lC);

    float lLocalAvg;
    if (gPos >= gNeg) { lLocalAvg = 0.5 * (lC + lPos); }
    else { stepLen = -stepLen; lLocalAvg = 0.5 * (lC + lNeg); }

    float2 edgeUv = uv;
    if (horz) { edgeUv.y += stepLen * 0.5; } else { edgeUv.x += stepLen * 0.5; }
    float2 edgeStep = horz ? float2(ts.x, 0.0) : float2(0.0, ts.y);

    const float STEPS[12] = { 1.0, 1.0, 1.0, 1.0, 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 4.0, 8.0 };
    float2 uvP = edgeUv, uvN = edgeUv;
    float dP = 0.0, dN = 0.0;
    bool hitP = false, hitN = false;
    [unroll] for (int i = 0; i < 12; ++i) {
        if (!hitP) { uvP += edgeStep * STEPS[i]; dP = Luma(Fetch(uvP)) - lLocalAvg; hitP = abs(dP) >= gPos * 0.5; }
        if (!hitN) { uvN -= edgeStep * STEPS[i]; dN = Luma(Fetch(uvN)) - lLocalAvg; hitN = abs(dN) >= gNeg * 0.5; }
        if (hitP && hitN) { break; }
    }

    float distP = horz ? (uvP.x - uv.x) : (uvP.y - uv.y);
    float distN = horz ? (uv.x - uvN.x) : (uv.y - uvN.y);
    float distMin = min(distP, distN);
    float edgeLen = distP + distN;
    float edgeOff = -distMin / max(edgeLen, 1e-6) + 0.5;

    bool cSmaller = lC < lLocalAvg;
    bool correct = (((distP < distN) ? dP : dN) >= 0.0) != cSmaller;
    float finalOff = max(correct ? edgeOff : 0.0, sub);

    float2 finalUv = uv;
    if (horz) { finalUv.y += finalOff * stepLen; } else { finalUv.x += finalOff * stepLen; }
    return float4(Fetch(finalUv), 1.0);
}
