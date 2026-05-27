// Forward PBR Vertex Shader
// Transforms vertices and passes data to fragment shader.
// Vertex format: Mesh (48 bytes) - position, normal, uv, color, tangent
//
// When INSTANCED is defined, reads per-instance transforms from a
// StructuredBuffer indexed by SV_InstanceID instead of the per-draw UBO.

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

// Set 3: Per-instance data (instanced path).
// The per-frame Instances buffer is indexed by entity (extraction order).
// Each draw delivers per-instance DataOffsets via vertex attribute (slot 1);
// the shader uses .x to fetch this instance's slot in Instances[].
struct InstanceData
{
    float4x4 WorldMatrix;
    float4x4 PrevWorldMatrix;
    // Per-instance color tint. Multiplied with the mesh's vertex color
    // and the material's albedo (frag shader). Default (1,1,1,1) is a
    // no-op. Used by mesh particles (per-particle Color stream) and
    // entity-level tinting via MeshComponent.Color.
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
    // Per-instance data offsets delivered via vertex buffer slot 1.
    // .x = entity index into Instances[]; .y/.z/.w reserved.
    uint4 DataOffsets : TEXCOORD5;
#endif
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

#ifdef INSTANCED
    uint instanceIndex = input.DataOffsets.x;
    float4x4 world = Instances[instanceIndex].WorldMatrix;
    float4x4 prevWorld = Instances[instanceIndex].PrevWorldMatrix;
    float4 instanceColor = Instances[instanceIndex].InstanceColor;
#else
    float4x4 world = WorldMatrix;
    float4x4 prevWorld = PrevWorldMatrix;
    float4 instanceColor = InstanceColor;
#endif

    float4 worldPos = mul(float4(input.Position, 1.0), world);
    output.WorldPos = worldPos.xyz;
    output.Position = mul(worldPos, ViewProjectionMatrix);
    output.WorldNormal = normalize(mul(input.Normal, (float3x3)world));
    output.WorldTangent = normalize(mul(input.Tangent, (float3x3)world));
    output.TexCoord = input.TexCoord;
    // Per-instance color tint flows through the existing vertex Color
    // channel; frag shader already multiplies it with albedo + material
    // BaseColor, and we extend the alpha path below.
    output.Color = input.Color * instanceColor;

    // Clip-space positions for motion vector output.
    output.CurClipPos = output.Position;
    float4 prevWorldPos = mul(float4(input.Position, 1.0), prevWorld);
    output.PrevClipPos = mul(prevWorldPos, PrevViewProjectionMatrix);

    return output;
}
