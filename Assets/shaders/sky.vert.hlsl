// Sky Vertex Shader — fullscreen triangle, reconstructs view ray

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

struct VertexOutput
{
    float4 Position : SV_Position;
    float3 ViewDir : TEXCOORD0;
};

VertexOutput main(uint vertexID : SV_VertexID)
{
    VertexOutput output;

    // Fullscreen triangle
    float2 uv = float2((vertexID << 1) & 2, vertexID & 2);
    float4 clipPos = float4(uv * 2.0 - 1.0, 1.0, 1.0);

    // Reconstruct world-space view direction from clip position
    float4 viewDir = mul(clipPos, InvViewProjectionMatrix);
    output.ViewDir = viewDir.xyz / viewDir.w - CameraPosition;

    output.Position = float4(uv * 2.0 - 1.0, 1.0, 1.0); // at far plane

    return output;
}
