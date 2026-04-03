// Test mesh shader with output topology and vertex/primitive counts.
//
// Compile:
//   dxc -T ms_6_5 -E MSMain -Fo test_mesh.dxil test_mesh.hlsl
//   dxc -T ms_6_5 -E MSMain -spirv -Fo test_mesh.spv test_mesh.hlsl

struct MeshVertex
{
    float4 Position : SV_POSITION;
    float4 Color    : COLOR0;
};

cbuffer MeshParams : register(b0, space0)
{
    float4x4 ViewProjection;
};

[outputtopology("triangle")]
[numthreads(32, 1, 1)]
void MSMain(
    uint gtid : SV_GroupThreadID,
    uint gid : SV_GroupID,
    out vertices MeshVertex verts[64],
    out indices uint3 tris[126])
{
    SetMeshOutputCounts(64, 126);

    if (gtid < 64)
    {
        MeshVertex v;
        v.Position = mul(ViewProjection, float4(float(gtid), float(gid), 0, 1));
        v.Color = float4(1, 1, 1, 1);
        verts[gtid] = v;
    }

    if (gtid < 126)
    {
        tris[gtid] = uint3(0, gtid + 1, gtid + 2);
    }
}
