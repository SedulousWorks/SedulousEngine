// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

#pragma pack_matrix(row_major)
static const uint MAX_PER_CLUSTER = 64;

cbuffer ClusterBuildParams : register(b0) {
    uint  GridX; uint GridY; uint SliceCount; uint TileSize;
    float Near;  float Far;  float LogScale;  float LogBias;
    uint  LightCount; uint LightOffset; float2 _pad;
    float4x4 ViewMatrix;
    float4x4 InvProjection;
};
struct GpuLight {
    float3 positionWS; float range;
    float3 color;      float intensity;
    float3 directionWS;float type;           // 0=Directional, 1=Point, 2=Spot
    float innerCos; float outerCos; float pad0; float pad1;
};
StructuredBuffer<GpuLight> Lights               : register(t0);
RWStructuredBuffer<uint2>  ClusterOffsetsRW      : register(u0);
RWStructuredBuffer<uint>   ClusterLightIndicesRW : register(u1);

float  GetSliceDepth(uint slice) { return Near * pow(Far / Near, (float)slice / (float)SliceCount); }
float2 ScreenToNDC(float2 s) {
    float w = (float)(GridX * TileSize);
    float h = (float)(GridY * TileSize);
    return float2(s.x / w * 2.0 - 1.0, s.y / h * 2.0 - 1.0);
}
// Unproject an NDC xy at positive view depth to view space (symmetric perspective; camera -Z).
float3 UnprojectToView(float2 ndc, float vd) {
    return float3(ndc.x * vd * InvProjection[0][0], ndc.y * vd * InvProjection[1][1], -vd);
}
bool SphereVsAABB(float3 c, float r, float3 mn, float3 mx) {
    float3 q = clamp(c, mn, mx);
    float3 d = c - q;
    return dot(d, d) <= r * r;
}

[numthreads(64, 1, 1)]
void main(uint3 dtid : SV_DispatchThreadID) {
    uint clusterIdx = dtid.x;
    uint total = GridX * GridY * SliceCount;
    if (clusterIdx >= total) { return; }

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

    uint base  = clusterIdx * MAX_PER_CLUSTER;
    uint count = 0;
    for (uint i = 0; i < LightCount && count < MAX_PER_CLUSTER; i++) {
        GpuLight L = Lights[LightOffset + i];
        bool hit;
        if (L.type < 0.5) {                                  // directional: affects every cluster
            hit = true;
        } else {                                             // point / spot: bounding sphere vs AABB
            float3 posV = mul(float4(L.positionWS, 1.0), ViewMatrix).xyz;
            hit = SphereVsAABB(posV, L.range, aabbMin, aabbMax);
        }
        if (hit) { ClusterLightIndicesRW[base + count] = i; count++; }
    }
    ClusterOffsetsRW[clusterIdx] = uint2(base, count);
}
