// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The editor's shader grid (DebugDraw::DrawGridPlane): one quad on the grid's plane, made here
// from the vertex index (no vertex buffer), `extent` metres each way from `origin`.
#include "push_constant.hlsli"
#include "depth.hlsli"
#include "debug_grid.hlsli"

static const float kDepthBias = 0.0005; // as debug_geom: beat TAA-jitter depth noise

GridVSOut main(uint id : SV_VertexID)
{
    const float2 corners[6] = {float2(-1, -1), float2(1, -1), float2(1, 1),
                               float2(-1, -1), float2(1, 1), float2(-1, 1)};
    const float2 c = corners[id];
    const float3 world = pc.OriginExtent.xyz +
                         (pc.AxisUSpacing.xyz * c.x + pc.AxisVBlend.xyz * c.y) * pc.OriginExtent.w;
    GridVSOut o;
    o.pos = BiasClipTowardViewer(mul(float4(world, 1.0), pc.ViewProj), kDepthBias);
    o.world = world;
    return o;
}
