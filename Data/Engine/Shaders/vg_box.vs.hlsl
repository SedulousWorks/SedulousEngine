// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// VG analytic box vertex shader (VGDrawMode::Box, VGContext::DrawBox). Every vertex carries the
// whole box: the device position goes through the projection, the box-local point is interpolated
// (exact under any affine transform), and the box's size, radii, borders and colours (a border
// colour per side) pass flat to
// vg_box.ps. Colours are authored sRGB: decoded as vg.vs does, or kept for an Encoded canvas.
// Resolved via ShaderSystem::GetVariant("vg_box", Vertex).
#pragma pack_matrix(row_major)
#include "color.hlsli"
cbuffer VGUniforms : register(b0) { float4x4 Projection; float DistanceFieldPixelRange; float DistanceFieldAtlasWidth; float DistanceFieldAtlasHeight; float BlendSpace; };
struct VSInput
{
    float2 Position : TEXCOORD0;
    float2 Local : TEXCOORD1;
    float2 HalfSize : TEXCOORD2;
    float4 Radii : TEXCOORD3;
    float4 Borders : TEXCOORD4;
    float4 Fill : TEXCOORD5;
    float4 BorderTop : TEXCOORD6;
    float4 BorderRight : TEXCOORD7;
    float4 BorderBottom : TEXCOORD8;
    float4 BorderLeft : TEXCOORD9;
};
struct VSOutput
{
    float4 Position : SV_Position;
    float2 Local : TEXCOORD0;
    nointerpolation float2 HalfSize : TEXCOORD1;
    nointerpolation float4 Radii : TEXCOORD2;
    nointerpolation float4 Borders : TEXCOORD3;
    nointerpolation float4 Fill : COLOR0;
    nointerpolation float4 BorderTop : COLOR1;
    nointerpolation float4 BorderRight : COLOR2;
    nointerpolation float4 BorderBottom : COLOR3;
    nointerpolation float4 BorderLeft : COLOR4;
};
float4 Decoded(float4 color, bool encoded)
{
    return float4(encoded ? color.rgb : SrgbToLinear(color.rgb), color.a);
}
VSOutput main(VSInput input)
{
    VSOutput o;
    o.Position = mul(float4(input.Position, 0.0, 1.0), Projection);
    o.Local = input.Local;
    o.HalfSize = input.HalfSize;
    o.Radii = input.Radii;
    o.Borders = input.Borders;
    const bool encoded = BlendSpace > 0.5;
    o.Fill = Decoded(input.Fill, encoded);
    o.BorderTop = Decoded(input.BorderTop, encoded);
    o.BorderRight = Decoded(input.BorderRight, encoded);
    o.BorderBottom = Decoded(input.BorderBottom, encoded);
    o.BorderLeft = Decoded(input.BorderLeft, encoded);
    return o;
}
