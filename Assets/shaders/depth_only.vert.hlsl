// Depth-only vertex shader
// Transforms position only - no color output, just depth buffer write.
//
// When INSTANCED is defined, reads per-instance transforms from a
// StructuredBuffer indexed by SV_InstanceID instead of the per-draw UBO.

#pragma pack_matrix(row_major)

cbuffer SceneUniforms : register(b0, space0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
    float4x4 ViewProjectionMatrix;
    // ... rest not needed for depth only
};

#ifdef INSTANCED

// Set 3: shared per-frame instance buffer (matches forward.vert).
// The InstanceColor field is unused here but kept so the struct stride
// matches the shared layout (144 bytes); otherwise Instances[i] for i>0
// would read at the wrong offset.
struct InstanceData
{
    float4x4 WorldMatrix;
    float4x4 PrevWorldMatrix;
    float4 InstanceColor;
};

StructuredBuffer<InstanceData> Instances : register(t0, space3);

#else

// Set 3: Per-draw data (non-instanced path)
cbuffer ObjectUniforms : register(b0, space3)
{
    float4x4 WorldMatrix;
    float4x4 PrevWorldMatrix;
    float4 InstanceColor; // unused; kept for layout parity with the CPU struct
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
    uint4 DataOffsets : TEXCOORD5;
#endif
};

float4 main(VertexInput input) : SV_Position
{
#ifdef INSTANCED
    float4x4 world = Instances[input.DataOffsets.x].WorldMatrix;
#else
    float4x4 world = WorldMatrix;
#endif
    float4 worldPos = mul(float4(input.Position, 1.0), world);
    return mul(worldPos, ViewProjectionMatrix);
}
