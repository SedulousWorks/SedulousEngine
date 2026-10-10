// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The editor's shader grid: lines at whole multiples of the spacing in world coordinates,
// anti-aliased by their screen-space footprint (one pixel wide at any distance), a heavier line
// every tenth, the finest decade fading out as the camera climbs (blend) while the next comes
// in, the two lines through the world origin in their axis's colour, all fading with distance
// and at grazing angles (where a plane seen edge-on would only moire).
#include "push_constant.hlsli"
#include "color.hlsli"
#include "debug_grid.hlsli"

// Coverage of the lines every `spacing` along both coordinates, about a pixel wide.
float LinesAt(float2 coord, float spacing)
{
    const float2 g = coord / spacing;
    const float2 footprint = max(fwidth(g), 1e-5);
    const float2 d = abs(frac(g - 0.5) - 0.5) / footprint;
    return 1.0 - saturate(min(d.x, d.y));
}

// Coverage of the one line where `c` is zero, a little wider than the grid's.
float OriginLine(float c)
{
    return 1.0 - saturate(abs(c) / max(fwidth(c) * 1.5, 1e-5));
}

// An axis's colour (authored sRGB, as the scene's origin axes): red X, green Y, blue Z.
float3 AxisColor(float3 dir)
{
    const float3 a = abs(dir);
    const float3 srgb = a.x > 0.5 ? float3(0.9, 0.2, 0.2) : (a.y > 0.5 ? float3(0.2, 0.9, 0.2)
                                                                      : float3(0.2, 0.4, 0.95));
    return SrgbToLinear(srgb);
}

float4 main(GridVSOut i) : SV_Target
{
    const float3 u = pc.AxisUSpacing.xyz;
    const float3 v = pc.AxisVBlend.xyz;
    const float spacing = pc.AxisUSpacing.w;
    const float blend = pc.AxisVBlend.w;
    const float2 coord = float2(dot(i.world, u), dot(i.world, v));

    // Three decades: the finest fading out, the middle easing from major to minor, the coarsest
    // coming in as major, so the spacing steps with the camera's height without a pop.
    const float kMinor = 0.28;
    const float kMajor = 0.6;
    float alpha = max(max(LinesAt(coord, spacing) * kMinor * (1.0 - blend),
                          LinesAt(coord, spacing * 10.0) * lerp(kMajor, kMinor, blend)),
                      LinesAt(coord, spacing * 100.0) * kMajor * blend);
    float3 color = SrgbToLinear(float3(0.63, 0.63, 0.65));

    // The axes through the origin: the u axis runs where the v coordinate is zero.
    const float onU = OriginLine(coord.y);
    const float onV = OriginLine(coord.x);
    color = lerp(color, AxisColor(u), onU);
    color = lerp(color, AxisColor(v), onV * (1.0 - onU));
    alpha = max(alpha, max(onU, onV) * 0.85);

    // Fade with distance from the camera, and where the plane is seen edge-on.
    const float3 toCamera = pc.CameraFade.xyz - i.world;
    const float distance = length(toCamera);
    const float fade = 1.0 - smoothstep(pc.CameraFade.w * 0.35, pc.CameraFade.w, distance);
    const float3 normal = normalize(cross(u, v));
    const float facing = saturate(abs(dot(toCamera / max(distance, 1e-4), normal)) * 6.0);
    return float4(color, alpha * fade * facing);
}
