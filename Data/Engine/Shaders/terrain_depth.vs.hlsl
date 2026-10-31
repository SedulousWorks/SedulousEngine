// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#pragma pack_matrix(row_major)

// Terrain DEPTH-only VS (camera depth prepass + CSM cascade passes). Replays terrain.vs's exact height
// displacement + world placement, but outputs ONLY clip position (no fragment stage - opaque casters
// are vertex-only). ViewProj is the camera VP (prepass) or a cascade's world->light-clip (shadow pass);
// ChunkToWorld places the heightfield instance. Skirt verts are never drawn in the depth pass (the
// renderer binds only the surface index range), so the skirt flag is ignored here.
//
// Declares only the two matrices it needs from the shared TerrainView cbuffer (offsets 0 and 64).
// No HOLES variant: a holed chunk's depth draws (prepass AND cascades) use the "terrain" VS module
// the colour pass rasterizes with, paired with terrain_depth.ps (see TerrainRenderer's depth PSO).

cbuffer TerrainView : register(b0, space0) {
    float4x4 ChunkToWorld; // heightfield-local -> world
    float4x4 ViewProj;     // world -> clip (camera prepass) OR world -> cascade light-clip (shadow pass)
};

cbuffer TerrainChunk : register(b0, space1) {
    float2 OriginXZ;
    float2 SizeXZ;
    float2 TexelBase;
    float2 TexelSpan;
    float2 HeightRange;
    float2 GridSize;
    float2 Skirt;
};

Texture2D<uint> HeightTex : register(t0, space2);

float SampleHeightY(int2 texel) {
    int2 m = clamp(texel, int2(0, 0), int2((int)GridSize.x - 1, (int)GridSize.y - 1));
    uint s = HeightTex.Load(int3(m, 0)).r;
    return HeightRange.x + ((float)s / 65535.0) * (HeightRange.y - HeightRange.x);
}

float4 main(float3 grid : TEXCOORD0) : SV_Position {
    float2 uv     = grid.xy;
    float2 texelF = TexelBase + uv * TexelSpan;
    int2   texel  = int2((int)round(texelF.x), (int)round(texelF.y));
    float  y      = SampleHeightY(texel); // surface only in the depth pass (no skirt drop)
    float2 lxz    = OriginXZ + uv * SizeXZ;
    float3 worldPos = mul(float4(lxz.x, y, lxz.y, 1.0), ChunkToWorld).xyz;
    return mul(float4(worldPos, 1.0), ViewProj);
}
