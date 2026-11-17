// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#pragma pack_matrix(row_major)
static const uint MAX_PER_CLUSTER = 64;

cbuffer ClusterBuildParams : register(b0) {
    uint  GridX; uint GridY; uint SliceCount; uint TileSize;
    float Near;  float Far;  float LogScale;  float LogBias;
    uint  LightCount; uint LightOffset; uint Orthographic; uint SlotsPerCluster;
    float4x4 ViewMatrix;
    float4x4 InvProjection;
};
struct GpuLight {
    float3 positionWS; float range;
    float3 color;      float intensity;
    float3 directionWS;float type;           // 0=Directional, 1=Point, 2=Spot
    float innerCos; float outerCos; float shadowIndex; float shadowStrength; // as lighting.hlsli
};
StructuredBuffer<GpuLight> Lights               : register(t0);
RWStructuredBuffer<uint2>  ClusterOffsetsRW      : register(u0);
RWStructuredBuffer<uint>   ClusterLightIndicesRW : register(u1);
// One shared list, a region of it for each group of 64 clusters (SlotsPerCluster each on average):
// in its group's region each cluster takes a run as long as its own lights, where the counts before
// it end, rather than a fixed 64 slots each, mostly empty. No atomics: WebGPU's shaders take none
// on a plain buffer.
groupshared uint gRunStart[64];

float  GetSliceDepth(uint slice) { return Near * pow(Far / Near, (float)slice / (float)SliceCount); }
float2 ScreenToNDC(float2 s) {
    float w = (float)(GridX * TileSize);
    float h = (float)(GridY * TileSize);
    return float2(s.x / w * 2.0 - 1.0, s.y / h * 2.0 - 1.0);
}
// Unproject an NDC xy at positive view depth to view space (symmetric projection; camera -Z).
// A perspective tile widens with depth; an orthographic one keeps its width.
float3 UnprojectToView(float2 ndc, float vd) {
    float scale = (Orthographic != 0) ? 1.0 : vd;
    return float3(ndc.x * scale * InvProjection[0][0], ndc.y * scale * InvProjection[1][1], -vd);
}
bool SphereVsAABB(float3 c, float r, float3 mn, float3 mx) {
    float3 q = clamp(c, mn, mx);
    float3 d = c - q;
    return dot(d, d) <= r * r;
}

[numthreads(64, 1, 1)]
void main(uint3 dtid : SV_DispatchThreadID, uint3 gtid : SV_GroupThreadID, uint3 gid : SV_GroupID) {
    uint clusterIdx = dtid.x;
    uint total = GridX * GridY * SliceCount;
    // No early return: every thread of the group reaches the barriers below (one past the grid counts 0).
    bool inGrid = clusterIdx < total;
    if (!inGrid) { clusterIdx = total - 1; }

    uint slice = clusterIdx / (GridX * GridY);
    uint tib   = clusterIdx % (GridX * GridY);
    uint tileY = tib / GridX;
    uint tileX = tib % GridX;

    float2 ndcMin = ScreenToNDC(float2((float)(tileX * TileSize),       (float)(tileY * TileSize)));
    float2 ndcMax = ScreenToNDC(float2((float)((tileX + 1) * TileSize), (float)((tileY + 1) * TileSize)));
    float  zN = GetSliceDepth(slice);
    float  zF = GetSliceDepth(slice + 1);

    float3 aabbMin = float3( 1e30,  1e30,  1e30);
    float3 aabbMax = float3(-1e30, -1e30, -1e30);
    float2 corners[4] = { ndcMin, float2(ndcMax.x, ndcMin.y), float2(ndcMin.x, ndcMax.y), ndcMax };
    [unroll] for (int c = 0; c < 4; c++) {
        float3 vN = UnprojectToView(corners[c], zN);
        float3 vF = UnprojectToView(corners[c], zF);
        aabbMin = min(aabbMin, min(vN, vF));
        aabbMax = max(aabbMax, max(vN, vF));
    }

    uint found[MAX_PER_CLUSTER];
    uint count = 0;
    for (uint i = 0; inGrid && i < LightCount && count < MAX_PER_CLUSTER; i++) {
        GpuLight L = Lights[LightOffset + i];
        bool hit;
        if (L.type < 0.5) {                                  // directional: affects every cluster
            hit = true;
        } else {                                             // point / spot: bounding sphere vs AABB
            float3 posV = mul(float4(L.positionWS, 1.0), ViewMatrix).xyz;
            hit = SphereVsAABB(posV, L.range, aabbMin, aabbMax);
        }
        if (hit) { found[count] = i; count++; }
    }
    // Where each cluster's run starts in the group's region: the counts before it, summed.
    gRunStart[gtid.x] = count;
    GroupMemoryBarrierWithGroupSync();
    if (gtid.x == 0) {
        uint run = 0;
        for (uint k = 0; k < 64; k++) { uint c = gRunStart[k]; gRunStart[k] = run; run += c; }
    }
    GroupMemoryBarrierWithGroupSync();
    // Past the region's end a cluster keeps what fits: the region is sized for the view's lights, so
    // only a crowd of large lights in one group's clusters reaches it.
    uint region = 64 * SlotsPerCluster;
    uint start  = gRunStart[gtid.x];
    uint kept   = (start >= region) ? 0 : min(count, region - start);
    uint base   = gid.x * region + start;
    if (inGrid) {
        for (uint k = 0; k < kept; k++) { ClusterLightIndicesRW[base + k] = found[k]; }
        ClusterOffsetsRW[clusterIdx] = uint2(base, kept);
    }
}
