// Entity pick vertex shader
// Transforms position and passes entity index to fragment shader.
// Outputs entity index encoded as RGBA8 color for GPU picking.
//
// With SKINNED the per-draw cbuffer also carries the bone-pool start
// index so the vertex shader can skin inline from the global pool,
// matching forward.vert / depth_only.vert.

#pragma pack_matrix(row_major)

cbuffer SceneUniforms : register(b0, space0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
    float4x4 ViewProjectionMatrix;
};

// Set 3: Per-draw data (world matrix + entity index)
cbuffer ObjectUniforms : register(b0, space3)
{
    float4x4 WorldMatrix;
    float4x4 PrevWorldMatrix;
    uint EntityIndex;
#ifdef SKINNED
    uint BoneStartIndex;
#endif
};

#ifdef SKINNED
struct BoneMatrix
{
    float4 Row0, Row1, Row2, Row3;
};
StructuredBuffer<BoneMatrix> BoneMatrices : register(t6, space0);
#endif

struct VertexInput
{
    float3 Position : TEXCOORD0;
    float3 Normal : TEXCOORD1;
    float2 TexCoord : TEXCOORD2;
    float4 Color : TEXCOORD3;
    float3 Tangent : TEXCOORD4;
#ifdef SKINNED
    // Joints / Weights at TEXCOORD 5 / 6 (not 6 / 7 like forward.vert).
    // DXC packs SPIR-V locations sequentially by declaration order, not
    // by the TEXCOORDN number - so to land at Locations 5 / 6, the
    // declarations have to be the 6th and 7th in struct order. The pick
    // pass binds a matching layout that puts the joint / weight attribs
    // at those locations (it isn't instanced, so it has no DataOffsets
    // claiming Location 5 the way forward/depth do).
    uint2 Joints : TEXCOORD5;
    float4 Weights : TEXCOORD6;
#endif
};

struct VertexOutput
{
    float4 Position : SV_Position;
    nointerpolation uint EntityIndex : TEXCOORD0;
};

VertexOutput main(VertexInput input)
{
    VertexOutput output;

    float3 position = input.Position;

#ifdef SKINNED
    uint4 jointIndices = uint4(
        input.Joints.x & 0xFFFF,
        (input.Joints.x >> 16) & 0xFFFF,
        input.Joints.y & 0xFFFF,
        (input.Joints.y >> 16) & 0xFFFF
    );
    BoneMatrix b0 = BoneMatrices[BoneStartIndex + jointIndices.x];
    BoneMatrix b1 = BoneMatrices[BoneStartIndex + jointIndices.y];
    BoneMatrix b2 = BoneMatrices[BoneStartIndex + jointIndices.z];
    BoneMatrix b3 = BoneMatrices[BoneStartIndex + jointIndices.w];
    float4x4 skinMatrix = float4x4(
        b0.Row0 * input.Weights.x + b1.Row0 * input.Weights.y + b2.Row0 * input.Weights.z + b3.Row0 * input.Weights.w,
        b0.Row1 * input.Weights.x + b1.Row1 * input.Weights.y + b2.Row1 * input.Weights.z + b3.Row1 * input.Weights.w,
        b0.Row2 * input.Weights.x + b1.Row2 * input.Weights.y + b2.Row2 * input.Weights.z + b3.Row2 * input.Weights.w,
        b0.Row3 * input.Weights.x + b1.Row3 * input.Weights.y + b2.Row3 * input.Weights.z + b3.Row3 * input.Weights.w
    );
    position = mul(float4(input.Position, 1.0), skinMatrix).xyz;
#endif

    float4 worldPos = mul(float4(position, 1.0), WorldMatrix);
    output.Position = mul(worldPos, ViewProjectionMatrix);
    output.EntityIndex = EntityIndex;
    return output;
}
