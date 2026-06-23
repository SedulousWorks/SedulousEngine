// Compute Skinning Shader
// Transforms skinned vertices (72 bytes) into standard mesh vertices (48 bytes).
// Blends 4 bone matrices per vertex. Bone indices packed as 4x uint16 in 2x uint32.
//
// One frame-scoped bind group covers every skinned-mesh dispatch:
//   - BoneMatrices, SourceVertices, OutputVertices: the shared pool buffers
//   - SkinningRecords: per-character offsets, written once per frame
// Push constant `RecordIndex` selects this dispatch's record; the shader
// reads absolute offsets/indices from it instead of taking a per-character
// descriptor rebind.

#pragma pack_matrix(row_major)

// DX12: root constants via register. Vulkan: push constants via attribute.
// Same convention as RHI Sample003_UniformBuffers / Sample018_Bindless.
struct PushData
{
    uint RecordIndex;
};
[[vk::push_constant]]
ConstantBuffer<PushData> gPush : register(b0, space1);

struct SkinningRecord
{
    uint SrcVertexOffset;   // byte offset into source pool
    uint OutVertexOffset;   // byte offset into output pool
    uint BoneMatrixStart;   // index (in matrices) into bone pool
    uint VertexCount;       // total vertices for this dispatch
};
StructuredBuffer<SkinningRecord> SkinningRecords : register(t2);

// Bone matrices: one slab per active skeleton, concatenated in the pool.
// float4 rows instead of float4x4 - see CONVENTIONS.md (StructuredBuffer matrix layout).
struct BoneMatrix
{
    float4 Row0, Row1, Row2, Row3;
};
StructuredBuffer<BoneMatrix> BoneMatrices : register(t0);

// Source vertices (72 bytes each) - read as raw bytes
ByteAddressBuffer SourceVertices : register(t1);

// Output vertices (48 bytes each) - write as raw bytes
RWByteAddressBuffer OutputVertices : register(u0);

[numthreads(64, 1, 1)]
void main(uint3 dtid : SV_DispatchThreadID)
{
    SkinningRecord record = SkinningRecords[gPush.RecordIndex];

    uint vertexIndex = dtid.x;
    if (vertexIndex >= record.VertexCount)
        return;

    // Read source vertex (72 bytes)
    // Layout: Position(12) Normal(12) TexCoord(8) Color(4) Tangent(12) Joints(8) Weights(16)
    uint srcOffset = record.SrcVertexOffset + vertexIndex * 72;

    float3 position = asfloat(SourceVertices.Load3(srcOffset));
    float3 normal = asfloat(SourceVertices.Load3(srcOffset + 12));
    float2 texCoord = asfloat(SourceVertices.Load2(srcOffset + 24));
    uint color = SourceVertices.Load(srcOffset + 32);
    float3 tangent = asfloat(SourceVertices.Load3(srcOffset + 36));

    // Unpack bone indices: 4x uint16 packed in 2x uint32. Offset by the per-record
    // bone-matrix start so each character's indices select its own slab in the pool.
    uint joints01 = SourceVertices.Load(srcOffset + 48);
    uint joints23 = SourceVertices.Load(srcOffset + 52);
    uint4 jointIndices = uint4(
        joints01 & 0xFFFF,
        (joints01 >> 16) & 0xFFFF,
        joints23 & 0xFFFF,
        (joints23 >> 16) & 0xFFFF
    ) + record.BoneMatrixStart;

    float4 weights = asfloat(SourceVertices.Load4(srcOffset + 56));

    // Reconstruct and blend bone matrices from float4 rows
    BoneMatrix bx = BoneMatrices[jointIndices.x];
    BoneMatrix by = BoneMatrices[jointIndices.y];
    BoneMatrix bz = BoneMatrices[jointIndices.z];
    BoneMatrix bw = BoneMatrices[jointIndices.w];

    float4x4 skinMatrix = float4x4(
        bx.Row0 * weights.x + by.Row0 * weights.y + bz.Row0 * weights.z + bw.Row0 * weights.w,
        bx.Row1 * weights.x + by.Row1 * weights.y + bz.Row1 * weights.z + bw.Row1 * weights.w,
        bx.Row2 * weights.x + by.Row2 * weights.y + bz.Row2 * weights.z + bw.Row2 * weights.w,
        bx.Row3 * weights.x + by.Row3 * weights.y + bz.Row3 * weights.z + bw.Row3 * weights.w
    );

    // Transform position (as point, w=1)
    float3 skinnedPos = mul(float4(position, 1.0), skinMatrix).xyz;

    // Transform normal and tangent (as direction, w=0), then normalize
    float3 skinnedNormal = normalize(mul(float4(normal, 0.0), skinMatrix).xyz);
    float3 skinnedTangent = normalize(mul(float4(tangent, 0.0), skinMatrix).xyz);

    // Write output vertex (48 bytes)
    // Layout: Position(12) Normal(12) TexCoord(8) Color(4) Tangent(12)
    uint dstOffset = record.OutVertexOffset + vertexIndex * 48;

    OutputVertices.Store3(dstOffset, asuint(skinnedPos));
    OutputVertices.Store3(dstOffset + 12, asuint(skinnedNormal));
    OutputVertices.Store2(dstOffset + 24, asuint(texCoord));
    OutputVertices.Store(dstOffset + 32, color);
    OutputVertices.Store3(dstOffset + 36, asuint(skinnedTangent));
}
