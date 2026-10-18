// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell
//
// The box's coverage and border here are adapted from GPUI's quad shader (Zed,
// crates/gpui_wgpu/src/shaders.wgsl: fs_quad, quad_sdf_impl, quarter_ellipse_sdf, pick_corner_radius),
// Copyright 2022 - 2025 Zed Industries, Inc., licensed under the Apache License, Version 2.0; see
// Dependencies/gpui/. Changed: ported from WGSL to HLSL, evaluated in box-local units under a transform
// (pixel distances by fwidth), solid fills only, no dashed borders, premultiplied output.

// VG analytic box fragment shader (VGDrawMode::Box). One signed distance gives the box's outer
// edge, and a second its border's inner edge (a quarter ellipse at a corner whose two borders
// differ), so fill and border cannot disagree, a thin border has no halo outside it, a zero-width
// side draws no fringe, and small radii are exact. The border is blended over the fill and the
// whole faded by the outer edge's half-pixel ramp; output is premultiplied for the
// PremultipliedAlpha blend. Resolved via ShaderSystem::GetVariant("vg_box", Fragment).
struct PSInput
{
    float4 Position : SV_Position;
    float2 Local : TEXCOORD0;
    nointerpolation float2 HalfSize : TEXCOORD1;
    nointerpolation float4 Radii : TEXCOORD2;   // top left, top right, bottom right, bottom left
    nointerpolation float4 Borders : TEXCOORD3; // top, right, bottom, left
    nointerpolation float4 Fill : COLOR0;
    nointerpolation float4 BorderColor : COLOR1;
};

// The corner radius of the quadrant the point is in.
float PickCornerRadius(float2 centerToPoint, float4 radii)
{
    if (centerToPoint.x < 0.0)
    {
        return centerToPoint.y < 0.0 ? radii.x : radii.w;
    }
    return centerToPoint.y < 0.0 ? radii.y : radii.z;
}

// Signed distance to a box inset by the corner radius, less that radius: negative inside.
float QuadSdf(float2 cornerCenterToPoint, float cornerRadius)
{
    if (cornerRadius == 0.0)
    {
        return max(cornerCenterToPoint.x, cornerCenterToPoint.y);
    }
    const float toInset = length(max(float2(0.0, 0.0), cornerCenterToPoint)) +
                          min(0.0, max(cornerCenterToPoint.x, cornerCenterToPoint.y));
    return toInset - cornerRadius;
}

// Approximate distance to a quarter ellipse (fine for antialiasing when not very eccentric):
// positive inside, negative outside.
float QuarterEllipseSdf(float2 p, float2 radii)
{
    const float2 circle = p / radii;
    return (length(circle) - 1.0) * (radii.x + radii.y) * -0.5;
}

// Premultiplied `above` over `below` (both straight alpha in, straight out).
float4 Over(float4 below, float4 above)
{
    const float alpha = above.a + below.a * (1.0 - above.a);
    const float3 color = (above.rgb * above.a + below.rgb * below.a * (1.0 - above.a)) / max(alpha, 1e-6);
    return float4(color, alpha);
}

float4 main(PSInput input) : SV_Target
{
    // Box units per device pixel here: distances below are taken in pixels.
    const float2 width = fwidth(input.Local);
    const float unitsPerPixel = max(length(width) * 0.70710678, 1e-6);
    const float aa = 0.5; // a pixel's centre to its edge

    const float2 centerToPoint = input.Local;
    const float cornerRadius = PickCornerRadius(centerToPoint, input.Radii);
    // The nearest borders: horizontal (left or right), vertical (top or bottom).
    float2 border = float2(centerToPoint.x < 0.0 ? input.Borders.w : input.Borders.y,
                           centerToPoint.y < 0.0 ? input.Borders.x : input.Borders.z);
    // A zero-width side is pushed out half a pixel, so it draws no fringe.
    const float2 reducedBorder = float2(border.x == 0.0 ? -aa * unitsPerPixel : border.x,
                                        border.y == 0.0 ? -aa * unitsPerPixel : border.y);

    const float2 cornerToPoint = abs(centerToPoint) - input.HalfSize;
    const float2 cornerCenterToPoint = cornerToPoint + cornerRadius;
    const float2 straightInnerToPoint = cornerToPoint + reducedBorder;
    const bool beyondInnerStraight = straightInnerToPoint.x > 0.0 || straightInnerToPoint.y > 0.0;

    // Outer edge: positive outside the box. In pixels.
    const float outerSdf = QuadSdf(cornerCenterToPoint, cornerRadius) / unitsPerPixel;

    // Inner edge of the border: negative within the border, positive inside it. In pixels.
    float innerSdf;
    if (cornerCenterToPoint.x <= 0.0 || cornerCenterToPoint.y <= 0.0)
    {
        innerSdf = -max(straightInnerToPoint.x, straightInnerToPoint.y) / unitsPerPixel;
    }
    else if (beyondInnerStraight)
    {
        innerSdf = -1.0;
    }
    else if (reducedBorder.x == reducedBorder.y)
    {
        innerSdf = -(outerSdf + reducedBorder.x / unitsPerPixel);
    }
    else
    {
        const float2 ellipseRadii = max(float2(0.0, 0.0), cornerRadius - reducedBorder);
        innerSdf = QuarterEllipseSdf(cornerCenterToPoint, ellipseRadii) / unitsPerPixel;
    }

    float4 color = input.Fill;
    const float borderSdf = max(innerSdf, outerSdf);
    if (borderSdf < aa)
    {
        const float4 bordered = Over(input.Fill, input.BorderColor);
        color = lerp(input.Fill, bordered, saturate(aa - innerSdf));
    }
    color.a *= saturate(aa - outerSdf);
    color.rgb *= color.a; // premultiply
    return color;
}
