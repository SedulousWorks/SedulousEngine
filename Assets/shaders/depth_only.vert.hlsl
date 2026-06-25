// Depth-only vertex shader
// Transforms position only - no color output, just depth buffer write.
//
// When INSTANCED is defined, reads per-instance transforms from a
// StructuredBuffer indexed by SV_InstanceID instead of the per-draw UBO.

#pragma pack_matrix(row_major)

cbuffer SceneUniforms : register(b0, space0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
    float4x4 ViewProjectionMatrix;
    // ... rest not needed for depth only
};

#ifdef INSTANCED

// Set 3: shared per-frame instance buffer (matches forward.vert).
// The InstanceColor field is unused here but kept so the struct stride
// matches the shared layout (144 bytes); otherwise Instances[i] for i>0
// would read at the wrong offset.
struct InstanceData
{
    float4x4 WorldMatrix;
    float4x4 PrevWorldMatrix;
    float4 InstanceColor;
};

StructuredBuffer<InstanceData> Instances : register(t0, space3);

#else

// Set 3: Per-draw data (non-instanced path)
cbuffer ObjectUniforms : register(b0, space3)
{
    float4x4 WorldMatrix;
    float4x4 PrevWorldMatrix;
    float4 InstanceColor; // unused; kept for layout parity with the CPU struct
};

#endif

#ifdef SKINNED
// Mirror the frame-bind-group BoneMatrices binding from forward.vert.
// Same register so depth + forward share the bind point on set 0.

struct BoneMatrix
{
    float4 Row0, Row1, Row2, Row3;
};
StructuredBuffer<BoneMatrix> BoneMatrices : register(t6, space0);

float4x4 BlendBoneMatrices(uint4 jointIndices, float4 weights, uint boneStart)
{
    BoneMatrix b0 = BoneMatrices[boneStart + jointIndices.x];
    BoneMatrix b1 = BoneMatrices[boneStart + jointIndices.y];
    BoneMatrix b2 = BoneMatrices[boneStart + jointIndices.z];
    BoneMatrix b3 = BoneMatrices[boneStart + jointIndices.w];
    return float4x4(
        b0.Row0 * weights.x + b1.Row0 * weights.y + b2.Row0 * weights.z + b3.Row0 * weights.w,
        b0.Row1 * weights.x + b1.Row1 * weights.y + b2.Row1 * weights.z + b3.Row1 * weights.w,
        b0.Row2 * weights.x + b1.Row2 * weights.y + b2.Row2 * weights.z + b3.Row2 * weights.w,
        b0.Row3 * weights.x + b1.Row3 * weights.y + b2.Row3 * weights.z + b3.Row3 * weights.w
    );
}
#endif

struct VertexInput
{
    float3 Position : TEXCOORD0;
    float3 Normal : TEXCOORD1;
    float2 TexCoord : TEXCOORD2;
    float4 Color : TEXCOORD3;
    float3 Tangent : TEXCOORD4;
#ifdef INSTANCED
    uint4 DataOffsets : TEXCOORD5;
#endif
#ifdef SKINNED
    uint2 Joints : TEXCOORD6;
    float4 Weights : TEXCOORD7;
#endif
};

float4 main(VertexInput input) : SV_Position
{
#ifdef INSTANCED
    float4x4 world = Instances[input.DataOffsets.x].WorldMatrix;
#else
    float4x4 world = WorldMatrix;
#endif

    float3 position = input.Position;

#ifdef SKINNED
    uint4 jointIndices = uint4(
        input.Joints.x & 0xFFFF,
        (input.Joints.x >> 16) & 0xFFFF,
        input.Joints.y & 0xFFFF,
        (input.Joints.y >> 16) & 0xFFFF
    );
    uint boneStart = input.DataOffsets.y;
    float4x4 skinMatrix = BlendBoneMatrices(jointIndices, input.Weights, boneStart);
    position = mul(float4(input.Position, 1.0), skinMatrix).xyz;
#endif

    float4 worldPos = mul(float4(position, 1.0), world);
    return mul(worldPos, ViewProjectionMatrix);
}
