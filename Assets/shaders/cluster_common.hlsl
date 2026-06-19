// Cluster Common — shared between cluster_build.comp.hlsl and forward.frag.hlsl
//
// Defines the cluster grid layout and the function to map a fragment's
// screen position + view depth to a cluster index.

#ifndef CLUSTER_COMMON_HLSL
#define CLUSTER_COMMON_HLSL

// Cluster grid constants
static const uint CLUSTER_TILE_SIZE = 16;
static const uint CLUSTER_DEPTH_SLICES = 24;
static const uint CLUSTER_MAX_LIGHTS = 128;

cbuffer ClusterParams : register(b2, space0)
{
    uint ClusterGridX;      // ceil(screenWidth / CLUSTER_TILE_SIZE)
    uint ClusterGridY;      // ceil(screenHeight / CLUSTER_TILE_SIZE)
    uint ClusterSliceCount; // = CLUSTER_DEPTH_SLICES
    uint ClusterTileSize;   // = CLUSTER_TILE_SIZE
    float ClusterNear;      // camera near plane
    float ClusterFar;       // camera far plane
    float ClusterLogScale;  // 1.0 / log(far / near)
    float ClusterLogBias;   // -log(near) * ClusterLogScale
};

// Per-cluster (offset, count) into the global light index list.
StructuredBuffer<uint2> ClusterOffsets : register(t4, space0);

// Global compacted light index list. ClusterOffsets[c].x is the start
// index; read ClusterOffsets[c].y consecutive entries.
StructuredBuffer<uint> ClusterLightIndices : register(t5, space0);

/// Maps a fragment's screen position and positive view-space depth to a
/// linear cluster index into the 3D grid.
uint GetClusterIndex(float2 screenPos, float viewDepth)
{
    uint tileX = (uint)screenPos.x / CLUSTER_TILE_SIZE;
    // Flip Y: SV_Position.y=0 is at the top of the screen, but
    // the compute shader maps tile row 0 to NDC bottom (Y=-1).
    float screenH = (float)(ClusterGridY * CLUSTER_TILE_SIZE);
    uint tileY = (uint)((screenH - screenPos.y) / CLUSTER_TILE_SIZE);

    tileX = min(tileX, ClusterGridX - 1);
    tileY = min(tileY, ClusterGridY - 1);

    // Logarithmic depth slice: slice = log(depth) * scale + bias
    // Clamp to [0, sliceCount-1] to handle near-plane fragments.
    float logDepth = log(max(viewDepth, ClusterNear));
    int slice = (int)(logDepth * ClusterLogScale + ClusterLogBias);
    slice = clamp(slice, 0, (int)ClusterSliceCount - 1);

    return tileX + tileY * ClusterGridX + (uint)slice * ClusterGridX * ClusterGridY;
}

#endif // CLUSTER_COMMON_HLSL
