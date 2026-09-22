// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell
//
// WIND: a vertex sway for vegetation cards and tufts, included by the forward, shadow depth and
// pick vertex shaders under the WIND variant, which each stage declares in its variants line.
// The sway is a world space offset, sin(time * WindSpeed + hash(world XZ)) * WindStrength scaled
// by the vertex's height mask (local y over WindHeight, squared: the roots stay put and the tips
// move). The three parameters are MATERIAL properties, riding the forward set two block's spare
// lanes, so a card material opts in and a rock never sways; the renderer selects this variant
// only for a material whose WindStrength default is above nought, so every other material is
// byte identical to what it was. The same offset applies to the previous frame's position at the
// previous time, so the motion vectors follow the sway.

cbuffer Material : register(b0, space2) {
    float4 BaseColor;
    float  Metallic;
    float  Roughness;
    float  WindStrength;       // metres of sway at a full height mask (nought = never selected)
    float  WindSpeed;          // radians per second
    float4 EmissiveColor;
    float  OcclusionStrength;
    float  NormalScale;
    float  AlphaCutoff;
    float  WindHeight;         // the local y at which the sway reaches full strength (roots at y <= 0)
};

float3 WindSway(float3 worldPos, float localY, float time) {
    float mask  = saturate(localY / max(WindHeight, 1e-3));
    float phase = time * WindSpeed + dot(worldPos.xz, float2(0.37, 0.61));
    float sway  = sin(phase) * 0.7 + sin(phase * 2.3 + 1.7) * 0.3;
    return float3(sway, 0.0, 0.6 * sway) * (WindStrength * mask * mask);
}
