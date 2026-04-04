// Minimal unlit vertex shader
// Transforms position by VP matrix from scene uniforms (space0, b0)

#pragma pack_matrix(row_major)

cbuffer SceneUniforms : register(b0, space0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
    float4x4 ViewProjectionMatrix;
    float4x4 InvViewMatrix;
    float4x4 InvProjectionMatrix;
    float4x4 InvViewProjectionMatrix;
    float3 CameraPosition;
    float NearPlane;
    float FarPlane;
    float Time;
    float DeltaTime;
    float _Pad0;
    float2 ScreenSize;
    float2 InvScreenSize;
};

struct VertexInput
{
    float3 Position : POSITION;
    float4 Color : COLOR;
};

struct VertexOutput
{
    float4 Position : SV_Position;
    float4 Color : COLOR;
};

VertexOutput main(VertexInput input)
{
    VertexOutput output;
    output.Position = mul(float4(input.Position, 1.0), ViewProjectionMatrix);
    output.Color = input.Color;
    return output;
}
