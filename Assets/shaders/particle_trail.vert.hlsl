// Particle trail ribbon vertex shader.
// Trail vertices are pre-computed on CPU - position, UV, and color are
// passed through directly. No billboard expansion needed.

#pragma pack_matrix(row_major)

cbuffer SceneUniforms : register(b0, space0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
    float4x4 ViewProjectionMatrix;
};

struct VertexInput
{
    float3 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Color    : COLOR;
};

struct VertexOutput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
    float4 Color    : COLOR0;
};

VertexOutput main(VertexInput input)
{
    VertexOutput output;
    output.Position = mul(float4(input.Position, 1.0), ViewProjectionMatrix);
    output.TexCoord = input.TexCoord;
    output.Color = input.Color;
    return output;
}
