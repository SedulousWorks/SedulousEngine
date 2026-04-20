// Debug line vertex shader - transforms world-space line vertices to clip space.

#pragma pack_matrix(row_major)

cbuffer SceneUniforms : register(b0, space0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
    float4x4 ViewProjectionMatrix;
    // ... rest not needed
};

struct VertexInput
{
    float3 Position : POSITION;
    float4 Color : COLOR;
};

struct VertexOutput
{
    float4 Position : SV_Position;
    float4 Color : COLOR0;
};

VertexOutput main(VertexInput input)
{
    VertexOutput output;
    output.Position = mul(float4(input.Position, 1.0), ViewProjectionMatrix);
    output.Color = input.Color;
    return output;
}
