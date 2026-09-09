// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#pragma pack_matrix(row_major)

// Terrain chunk VS. ONE 65x65 grid (+ a skirt copy) is drawn for every chunk; this shader places each
// grid vertex in the WORLD (per-chunk OriginXZ + SizeXZ, then ChunkToWorld) and lifts it to the sampled
// height, fetched exactly from the R16Uint height texture via an integer Load. Positions/normals are
// world-space (the CSM cascade matrices are world-space, and the PS shadow-samples worldPos). The
// surface normal comes from central differences on the height texture. Emits current + previous clip
// for the GBuffer motion vector, and worldPos for the PS's shadow + lighting.

#define TERRAIN_CASCADE_COUNT 4
cbuffer TerrainView : register(b0, space0) {
    float4x4 ChunkToWorld;   // heightfield-local -> world
    float4x4 ViewProj;       // world -> clip (camera)
    float4x4 View;           // world -> view (GBuffer normal + shadow view-depth)
    float4x4 PrevViewProj;   // world -> clip, previous frame (motion vectors)
    float4x4 CascadeViewProj[TERRAIN_CASCADE_COUNT]; // world -> each cascade's light clip
    float4   LightDir;       // xyz = direction TO the light (normalized); w unused
    float4   CameraPos;      // xyz world camera
    float4   Jitter;         // xy = current TAA jitter, zw = previous
    float4   CascadeSplitFar;  // view-space far depth per cascade
    float4   CascadeTexelSize; // world units per texel per cascade
    float4   ShadowMeta;       // x = cascade count, y = layer base, z = normal bias, w = depth bias
    float4   ShadowParams;     // x = far-fade width, y = uv.y sign, zw spare
};

cbuffer TerrainChunk : register(b0, space1) {
    float2 OriginXZ;    // world XZ of the chunk's grid origin (pre-ChunkToWorld local frame)
    float2 SizeXZ;      // world XZ span of the chunk (kChunkQuads quads)
    float2 TexelBase;   // height-texture texel coord of the chunk origin (gridX0, gridZ0)
    float2 TexelSpan;   // texels spanned across the chunk (= kChunkQuads)
    float2 HeightRange; // minY, maxY (world)
    float2 GridSize;    // heightfield side S (texel clamp bound), same in x and y
    float2 Skirt;       // x = skirt drop depth (world); y = pad
};

Texture2D<uint> HeightTex : register(t0, space2);

struct VSIn  { float3 Grid : TEXCOORD0; };  // xy = grid uv in [0,1], z = skirt flag (0 surface, 1 skirt)
struct VSOut {
    float4 pos      : SV_Position;
    float3 normal   : TEXCOORD0; // world-space
    float  heightT  : TEXCOORD1; // 0..1 within [minY, maxY]
    float4 curClip  : TEXCOORD2;
    float4 prevClip : TEXCOORD3;
    float3 worldPos : TEXCOORD4;
    float2 localXZ  : TEXCOORD5; // terrain-LOCAL XZ (pre-ChunkToWorld) for albedo tiling
    float2 splatUV  : TEXCOORD6; // 0..1 across the terrain footprint (splatmap lookup)
};

float SampleHeightY(int2 texel) {
    int2 m = clamp(texel, int2(0, 0), int2((int)GridSize.x - 1, (int)GridSize.y - 1));
    uint s = HeightTex.Load(int3(m, 0)).r;
    return HeightRange.x + ((float)s / 65535.0) * (HeightRange.y - HeightRange.x);
}

VSOut main(VSIn i) {
    VSOut o;

    float2 uv       = i.Grid.xy;
    float  isSkirt  = i.Grid.z;
    float2 texelF   = TexelBase + uv * TexelSpan;
    int2   texel    = int2((int)round(texelF.x), (int)round(texelF.y));
    float  surfaceY = SampleHeightY(texel);
    float  y        = surfaceY - isSkirt * Skirt.x; // skirt verts drop below the surface

    float2 lxz = OriginXZ + uv * SizeXZ;                       // local XZ
    float3 worldPos = mul(float4(lxz.x, y, lxz.y, 1.0), ChunkToWorld).xyz;
    o.worldPos = worldPos;
    o.localXZ  = lxz;
    o.splatUV  = texelF / max(GridSize, float2(1.0, 1.0)); // 0..1 across the terrain footprint
    o.pos      = mul(float4(worldPos, 1.0), ViewProj);
    o.curClip  = o.pos;
    o.prevClip = mul(float4(worldPos, 1.0), PrevViewProj);

    // Normal from central differences on the height texture (world units per texel = SizeXZ / span),
    // then rotated into world space by ChunkToWorld (translation ignored via w=0).
    float hL = SampleHeightY(texel + int2(-1,  0));
    float hR = SampleHeightY(texel + int2( 1,  0));
    float hD = SampleHeightY(texel + int2( 0, -1));
    float hU = SampleHeightY(texel + int2( 0,  1));
    float2 cell = SizeXZ / max(TexelSpan, float2(1.0, 1.0));
    float3 nLocal = normalize(float3(hL - hR, cell.x + cell.y, hD - hU));
    o.normal  = normalize(mul(float4(nLocal, 0.0), ChunkToWorld).xyz);
    o.heightT = saturate((surfaceY - HeightRange.x) / max(HeightRange.y - HeightRange.x, 1e-3));
    return o;
}
