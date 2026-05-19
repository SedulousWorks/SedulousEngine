// Unlit Vertex Shader
// Simple vertex transformation without lighting.
// Same vertex format and set layout as forward shader.

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

#ifdef INSTANCED

// Set 3: Per-instance data - see CONVENTIONS.md
cbuffer InstanceParams : register(b0, space3)
{
    uint BaseInstance;
};

struct InstanceData
{
    float4x4 WorldMatrix;
    float4x4 PrevWorldMatrix;
    // Per-instance color tint (entity MeshComponent.Color / mesh-particle
    // Color stream). Must match forward.vert's layout so the shared
    // instance buffer reads at the right stride.
    float4 InstanceColor;
};

StructuredBuffer<InstanceData> Instances : register(t0, space3);

#else

// Set 3: Per-draw data (non-instanced path)
cbuffer ObjectUniforms : register(b0, space3)
{
    float4x4 WorldMatrix;
    float4x4 PrevWorldMatrix;
    float4 InstanceColor;
};

#endif

struct VertexInput
{
    float3 Position : TEXCOORD0;
    float3 Normal : TEXCOORD1;
    float2 TexCoord : TEXCOORD2;
    float4 Color : TEXCOORD3;
    float3 Tangent : TEXCOORD4;
#ifdef INSTANCED
    uint InstanceID : SV_InstanceID;
#endif
};

struct VertexOutput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
    float4 Color : TEXCOORD1;
};

VertexOutput main(VertexInput input)
{
    VertexOutput output;

#ifdef INSTANCED
    float4x4 world = Instances[input.InstanceID + BaseInstance].WorldMatrix;
    float4 instanceColor = Instances[input.InstanceID + BaseInstance].InstanceColor;
#else
    float4x4 world = WorldMatrix;
    float4 instanceColor = InstanceColor;
#endif

    float4 worldPos = mul(float4(input.Position, 1.0), world);
    output.Position = mul(worldPos, ViewProjectionMatrix);
    output.TexCoord = input.TexCoord;

#ifdef VERTEX_COLORS
    output.Color = input.Color * instanceColor;
#else
    output.Color = instanceColor;
#endif

    return output;
}
