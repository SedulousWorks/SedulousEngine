// Cluster Build Compute Shader
// Assigns lights to clusters in a 3D grid (screen tiles x depth slices).
// One thread per cluster. Builds a view-space AABB for the cluster using
// the inverse projection matrix, then tests each light's bounding sphere
// against it. Based on the proven approach from Sedulous-Serenity.

#pragma pack_matrix(row_major)

static const uint MAX_LIGHTS_PER_CLUSTER = 32;

cbuffer ClusterBuildParams : register(b0)
{
    uint GridX;
    uint GridY;
    uint SliceCount;
    uint TileSize;
    float Near;
    float Far;
    float LogScale;
    float LogBias;
    uint LightCount;
    float3 _Pad;
    float4x4 ViewMatrix;
    float4x4 InverseProjection;
};

struct GPULight
{
    float3 Position;
    float Type;       // 0=directional, 1=point, 2=spot
    float3 Direction;
    float Range;
    float3 Color;
    float Intensity;
    float InnerConeAngle;
    float OuterConeAngle;
    float ShadowBias;
    int   ShadowIndex;
};

StructuredBuffer<GPULight> Lights : register(t0);

// Output: per-cluster (offset, count)
RWStructuredBuffer<uint2> ClusterOffsetsRW : register(u0);

// Output: global light index list (flat, clusterIdx * MAX_LIGHTS_PER_CLUSTER)
RWStructuredBuffer<uint> ClusterLightIndicesRW : register(u1);

/// Get depth at a given slice using logarithmic distribution.
float GetSliceDepth(uint slice)
{
    return Near * pow(Far / Near, float(slice) / float(SliceCount));
}

/// Convert screen position to NDC [-1, 1].
float2 ScreenToNDC(float2 screenPos)
{
    float screenW = float(GridX * TileSize);
    float screenH = float(GridY * TileSize);
    return float2(
        (screenPos.x / screenW) * 2.0 - 1.0,
        (screenPos.y / screenH) * 2.0 - 1.0
    );
}

/// Unproject an NDC XY point at a given positive view depth to view space.
/// Uses the inverse projection matrix diagonal to convert NDC to view space.
/// For a symmetric perspective projection:
///   viewX = ndcX * depth / P[0][0]
///   viewY = ndcY * depth / P[1][1]
///   viewZ = -depth (camera looks down -Z in view space)
float3 UnprojectToView(float2 ndc, float viewDepth)
{
    // InverseProjection[0][0] = 1/P[0][0], InverseProjection[1][1] = 1/P[1][1]
    return float3(
        ndc.x * viewDepth * InverseProjection[0][0],
        ndc.y * viewDepth * InverseProjection[1][1],
        -viewDepth
    );
}

/// Test if a sphere intersects an AABB.
bool SphereIntersectsAABB(float3 center, float radius, float3 aabbMin, float3 aabbMax)
{
    float3 closest = clamp(center, aabbMin, aabbMax);
    float3 d = center - closest;
    return dot(d, d) <= radius * radius;
}

[numthreads(64, 1, 1)]
void main(uint3 dtid : SV_DispatchThreadID)
{
    uint clusterIdx = dtid.x;
    uint totalClusters = GridX * GridY * SliceCount;
    if (clusterIdx >= totalClusters)
        return;

    // Decompose linear index into (tileX, tileY, slice)
    uint slice = clusterIdx / (GridX * GridY);
    uint tileInSlice = clusterIdx % (GridX * GridY);
    uint tileY = tileInSlice / GridX;
    uint tileX = tileInSlice % GridX;

    // Screen-space tile bounds (pixels)
    float2 tileMinScreen = float2(float(tileX * TileSize), float(tileY * TileSize));
    float2 tileMaxScreen = float2(float((tileX + 1) * TileSize), float((tileY + 1) * TileSize));

    // Convert to NDC
    float2 ndcMin = ScreenToNDC(tileMinScreen);
    float2 ndcMax = ScreenToNDC(tileMaxScreen);

    // Depth slice bounds (logarithmic)
    float zNear = GetSliceDepth(slice);
    float zFar = GetSliceDepth(slice + 1);

    // Build view-space AABB from 8 frustum corners
    float3 aabbMin = float3(1e30, 1e30, 1e30);
    float3 aabbMax = float3(-1e30, -1e30, -1e30);

    float2 ndcCorners[4] = {
        float2(ndcMin.x, ndcMin.y),
        float2(ndcMax.x, ndcMin.y),
        float2(ndcMin.x, ndcMax.y),
        float2(ndcMax.x, ndcMax.y)
    };

    float depths[2] = { zNear, zFar };

    [unroll]
    for (int i = 0; i < 4; i++)
    {
        [unroll]
        for (int j = 0; j < 2; j++)
        {
            float3 viewPos = UnprojectToView(ndcCorners[i], depths[j]);
            aabbMin = min(aabbMin, viewPos);
            aabbMax = max(aabbMax, viewPos);
        }
    }

    // Test each light against this cluster's AABB
    uint baseOffset = clusterIdx * MAX_LIGHTS_PER_CLUSTER;
    uint count = 0;

    for (uint i = 0; i < LightCount && count < MAX_LIGHTS_PER_CLUSTER; i++)
    {
        GPULight light = Lights[i];

        if (light.Type < 0.5)
        {
            // Directional light: affects all clusters
            ClusterLightIndicesRW[baseOffset + count] = i;
            count++;
        }
        else
        {
            // Point or spot light: transform to view space, sphere-AABB test
            float3 viewPos = mul(float4(light.Position, 1.0), ViewMatrix).xyz;

            if (SphereIntersectsAABB(viewPos, light.Range, aabbMin, aabbMax))
            {
                ClusterLightIndicesRW[baseOffset + count] = i;
                count++;
            }
        }
    }

    ClusterOffsetsRW[clusterIdx] = uint2(baseOffset, count);
}
