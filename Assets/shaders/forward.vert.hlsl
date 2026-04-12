// Forward PBR Vertex Shader
// Transforms vertices and passes data to fragment shader.
// Vertex format: Mesh (48 bytes) — position, normal, uv, color, tangent

#pragma pack_matrix(row_major)

// Set 0: Frame data
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

// Set 3: Per-draw data
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

struct VertexOutput
{
    float4 Position : SV_Position;
    float3 WorldPos : TEXCOORD0;
    float3 WorldNormal : TEXCOORD1;
    float2 TexCoord : TEXCOORD2;
    float4 Color : TEXCOORD3;
    float3 WorldTangent : TEXCOORD4;
    // Current and previous clip-space positions for motion vector computation.
    float4 CurClipPos : TEXCOORD5;
    float4 PrevClipPos : TEXCOORD6;
};

VertexOutput main(VertexInput input)
{
    VertexOutput output;

    float4 worldPos = mul(float4(input.Position, 1.0), WorldMatrix);
    output.WorldPos = worldPos.xyz;
    output.Position = mul(worldPos, ViewProjectionMatrix);
    output.WorldNormal = normalize(mul(input.Normal, (float3x3)WorldMatrix));
    output.WorldTangent = normalize(mul(input.Tangent, (float3x3)WorldMatrix));
    output.TexCoord = input.TexCoord;
    output.Color = input.Color;

    // Clip-space positions for motion vector output.
    output.CurClipPos = output.Position;
    float4 prevWorldPos = mul(float4(input.Position, 1.0), PrevWorldMatrix);
    output.PrevClipPos = mul(prevWorldPos, PrevViewProjectionMatrix);

    return output;
}
