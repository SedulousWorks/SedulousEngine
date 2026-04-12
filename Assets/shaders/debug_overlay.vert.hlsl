// Debug overlay vertex shader — maps pixel-space positions to clip space.
// Used for 2D text and filled rectangles in screen space.

#pragma pack_matrix(row_major)

cbuffer SceneUniforms : register(b0, space0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
    float4x4 ViewProjectionMatrix;
    float4x4 InvViewMatrix;
    float4x4 InvProjectionMatrix;
    float4x4 InvViewProjectionMatrix;
    float4x4 PrevViewProjectionMatrix;
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
    float3 Position : POSITION;  // x, y in pixels; z unused
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR;
};

struct VertexOutput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR0;
};

VertexOutput main(VertexInput input)
{
    VertexOutput output;
    // Pixel (0,0) = top-left → NDC (-1, 1)
    // Pixel (w,h) = bottom-right → NDC (1, -1)
    // (The Vulkan backend uses negative viewport height to match DX convention.)
    float2 ndc = float2(
        (input.Position.x * InvScreenSize.x) * 2.0 - 1.0,
        1.0 - (input.Position.y * InvScreenSize.y) * 2.0
    );
    output.Position = float4(ndc, 0.0, 1.0);
    output.TexCoord = input.TexCoord;
    output.Color = input.Color;
    return output;
}
