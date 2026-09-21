// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#pragma pack_matrix(row_major)

// Terrain GPU-pick VS: terrain_depth.vs's exact displacement + placement, plus the terrain
// entity's id for the fragment. The renderer writes a PickView layout into the shared TerrainView
// slot for this pass (ChunkToWorld, the CROPPED ViewProj, then the id), so only that prefix is
// declared here. Surface indices only, like the depth pass.

cbuffer TerrainView : register(b0, space0) {
    float4x4 ChunkToWorld; // heightfield-local -> world
    float4x4 ViewProj;     // world -> clip (the pick crop)
    uint2    PickId;       // (entity index + 1, generation)
    uint2    _pvPad;
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

struct PickVSOut {
    float4 pos : SV_Position;
    nointerpolation uint2 id : TEXCOORD0;
};

PickVSOut main(float3 grid : TEXCOORD0) {
    float2 uv     = grid.xy;
    float2 texelF = TexelBase + uv * TexelSpan;
    int2   texel  = int2((int)round(texelF.x), (int)round(texelF.y));
    float  y      = SampleHeightY(texel);
    float2 lxz    = OriginXZ + uv * SizeXZ;
    float3 worldPos = mul(float4(lxz.x, y, lxz.y, 1.0), ChunkToWorld).xyz;
    PickVSOut o;
    o.pos = mul(float4(worldPos, 1.0), ViewProj);
    o.id  = PickId;
    return o;
}
