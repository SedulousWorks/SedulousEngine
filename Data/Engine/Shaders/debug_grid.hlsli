// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The shader grid's push block, read by both stages (DebugDrawPass's GridPush mirrors it).
#ifndef DEBUG_GRID_HLSLI
#define DEBUG_GRID_HLSLI

struct GridPush
{
    row_major float4x4 ViewProj;
    float4 OriginExtent; // xyz: the quad's centre on the plane; w: metres each way
    float4 AxisUSpacing; // xyz: the plane's first axis; w: the finest line spacing, metres
    float4 AxisVBlend;   // xyz: the plane's second axis; w: 0..1 toward the next decade
    float4 CameraFade;   // xyz: the camera; w: the distance the grid has faded out by
};
PUSH_CONSTANT(GridPush, pc, space0);

struct GridVSOut
{
    float4 pos : SV_Position;
    float3 world : TEXCOORD0;
};

#endif
