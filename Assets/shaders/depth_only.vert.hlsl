// Depth-only vertex shader
// Transforms position only — no color output, just depth buffer write.

#pragma pack_matrix(row_major)

cbuffer SceneUniforms : register(b0, space0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
    float4x4 ViewProjectionMatrix;
    // ... rest not needed for depth only
};

cbuffer ObjectUniforms : register(b0, space3)
{
    float4x4 WorldMatrix;
    float4x4 PrevWorldMatrix;
};

struct VertexInput
{
    float3 Position : POSITION;
    float3 Normal : NORMAL;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR;
    float3 Tangent : TANGENT;
};

float4 main(VertexInput input) : SV_Position
{
    float4 worldPos = mul(float4(input.Position, 1.0), WorldMatrix);
    return mul(worldPos, ViewProjectionMatrix);
}
