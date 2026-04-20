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

// Set 3: Per-instance data (instanced path)
struct InstanceData
{
    float4x4 WorldMatrix;
    float4x4 PrevWorldMatrix;
};

StructuredBuffer<InstanceData> Instances : register(t0, space3);

#else

// Set 3: Per-draw data (non-instanced path)
cbuffer ObjectUniforms : register(b0, space3)
{
    float4x4 WorldMatrix;
    float4x4 PrevWorldMatrix;
};

#endif

struct VertexInput
{
    float3 Position : POSITION;
    float3 Normal : NORMAL;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR;
    float3 Tangent : TANGENT;
#ifdef INSTANCED
    uint InstanceID : SV_InstanceID;
#endif
};

float4 main(VertexInput input) : SV_Position
{
#ifdef INSTANCED
    float4x4 world = Instances[input.InstanceID].WorldMatrix;
#else
    float4x4 world = WorldMatrix;
#endif
    float4 worldPos = mul(float4(input.Position, 1.0), world);
    return mul(worldPos, ViewProjectionMatrix);
}
