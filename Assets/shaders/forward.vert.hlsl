// Forward PBR Vertex Shader
// Transforms vertices and passes data to fragment shader.
// Vertex format: Mesh (48 bytes) - position, normal, uv, color, tangent.
// With SKINNED the input stride grows to 72 bytes - extra Joints
// (uint2 packed as 4x uint16) and Weights (float4) attributes; the
// vertex shader blends bone matrices from the global pool inline.
//
// When INSTANCED is defined, reads per-instance transforms from a
// StructuredBuffer indexed via the DataOffsets vertex attribute
// (avoiding the SV_InstanceID / firstInstance trap between HLSL and
// SPIR-V).

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

#ifdef SKINNED
// Global bone matrix pool, shared by every skinned instance this frame.
// Bound into the frame bind group (set 0). Each bone is 4 float4 rows
// (64 bytes).
struct BoneMatrix
{
    float4 Row0, Row1, Row2, Row3;
};
StructuredBuffer<BoneMatrix> BoneMatrices : register(t6, space0);

float4x4 BlendBoneMatrices(uint4 jointIndices, float4 weights, uint boneStart)
{
    BoneMatrix b0 = BoneMatrices[boneStart + jointIndices.x];
    BoneMatrix b1 = BoneMatrices[boneStart + jointIndices.y];
    BoneMatrix b2 = BoneMatrices[boneStart + jointIndices.z];
    BoneMatrix b3 = BoneMatrices[boneStart + jointIndices.w];
    return float4x4(
        b0.Row0 * weights.x + b1.Row0 * weights.y + b2.Row0 * weights.z + b3.Row0 * weights.w,
        b0.Row1 * weights.x + b1.Row1 * weights.y + b2.Row1 * weights.z + b3.Row1 * weights.w,
        b0.Row2 * weights.x + b1.Row2 * weights.y + b2.Row2 * weights.z + b3.Row2 * weights.w,
        b0.Row3 * weights.x + b1.Row3 * weights.y + b2.Row3 * weights.z + b3.Row3 * weights.w
    );
}
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
    // .x = entity index into Instances[].
    // .y = bone matrix start (SKINNED only; 0 otherwise).
    // .z = prev-frame bone matrix start (motion vectors). .w reserved.
    uint4 DataOffsets : TEXCOORD5;
#endif
#ifdef SKINNED
    // Skinned input attributes (extra 24 bytes vs the static layout).
    // Joints: 4 uint16 packed into 2 uint32.
    uint2 Joints : TEXCOORD6;
    float4 Weights : TEXCOORD7;
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

    // Default to the raw vertex; skinned path overrides position / normal /
    // tangent (and the prev-frame position for motion vectors) before the
    // world transform.
    float3 position = input.Position;
    float3 normal = input.Normal;
    float3 tangent = input.Tangent;
    float3 prevPosition = input.Position;

#ifdef SKINNED
    // Unpack 4 uint16 joint indices from 2 packed uint32.
    uint4 jointIndices = uint4(
        input.Joints.x & 0xFFFF,
        (input.Joints.x >> 16) & 0xFFFF,
        input.Joints.y & 0xFFFF,
        (input.Joints.y >> 16) & 0xFFFF
    );

    uint boneStart = input.DataOffsets.y;
    uint prevBoneStart = input.DataOffsets.z;

    float4x4 skinMatrix = BlendBoneMatrices(jointIndices, input.Weights, boneStart);
    position = mul(float4(input.Position, 1.0), skinMatrix).xyz;
    normal = mul(float4(input.Normal, 0.0), skinMatrix).xyz;
    tangent = mul(float4(input.Tangent, 0.0), skinMatrix).xyz;

    // Per-bone motion blur: skin against the previous frame's bones so the
    // prev clip-space position reflects bone motion as well as object motion.
    float4x4 prevSkinMatrix = BlendBoneMatrices(jointIndices, input.Weights, prevBoneStart);
    prevPosition = mul(float4(input.Position, 1.0), prevSkinMatrix).xyz;
#endif

    float4 worldPos = mul(float4(position, 1.0), world);
    output.WorldPos = worldPos.xyz;
    output.Position = mul(worldPos, ViewProjectionMatrix);
    output.WorldNormal = normalize(mul(normal, (float3x3)world));
    output.WorldTangent = normalize(mul(tangent, (float3x3)world));
    output.TexCoord = input.TexCoord;
    // Per-instance color tint flows through the existing vertex Color
    // channel; frag shader already multiplies it with albedo + material
    // BaseColor, and we extend the alpha path below.
    output.Color = input.Color * instanceColor;

    // Clip-space positions for motion vector output.
    output.CurClipPos = output.Position;
    float4 prevWorldPos = mul(float4(prevPosition, 1.0), prevWorld);
    output.PrevClipPos = mul(prevWorldPos, PrevViewProjectionMatrix);

    return output;
}
