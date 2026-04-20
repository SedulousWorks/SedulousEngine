// Decal vertex shader - generates 36 vertices of a unit cube from SV_VertexID,
// transforms them by the decal's world matrix, and projects to clip space.
//
// The cube is rendered in the decal's local space centered at origin with
// extents [-0.5, 0.5]. The decal's world matrix places and orients it.
// Fragment shader is responsible for clipping to the volume and sampling
// the decal texture via scene depth reconstruction.

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
    float3   CameraPosition;
    float    NearPlane;
    float    FarPlane;
    float    Time;
    float    DeltaTime;
    float    _Pad0;
    float2   ScreenSize;
    float2   InvScreenSize;
};

cbuffer DecalUniforms : register(b0, space3)
{
    float4x4 DecalWorld;
    float4x4 DecalInvWorld;
    float4   DecalColor;
    float    AngleFadeStart;
    float    AngleFadeEnd;
    float2   _DecalPad;
};

struct VertexOutput
{
    float4 Position : SV_Position;
    float2 ScreenUV : TEXCOORD0;
};

VertexOutput main(uint vertexID : SV_VertexID)
{
    // 36 cube vertices - 6 faces × 2 triangles × 3 vertices. Cube extent [-0.5, 0.5].
    // Winding is intentionally mixed; DecalRenderer draws with CullMode.None so
    // both sides of each face are rasterized regardless.
    static const float3 CubeVerts[36] = {
        // -Z face
        float3(-0.5, -0.5, -0.5), float3(-0.5,  0.5, -0.5), float3( 0.5,  0.5, -0.5),
        float3(-0.5, -0.5, -0.5), float3( 0.5,  0.5, -0.5), float3( 0.5, -0.5, -0.5),
        // +Z face
        float3(-0.5, -0.5,  0.5), float3( 0.5, -0.5,  0.5), float3( 0.5,  0.5,  0.5),
        float3(-0.5, -0.5,  0.5), float3( 0.5,  0.5,  0.5), float3(-0.5,  0.5,  0.5),
        // -X face
        float3(-0.5, -0.5, -0.5), float3(-0.5, -0.5,  0.5), float3(-0.5,  0.5,  0.5),
        float3(-0.5, -0.5, -0.5), float3(-0.5,  0.5,  0.5), float3(-0.5,  0.5, -0.5),
        // +X face
        float3( 0.5, -0.5, -0.5), float3( 0.5,  0.5, -0.5), float3( 0.5,  0.5,  0.5),
        float3( 0.5, -0.5, -0.5), float3( 0.5,  0.5,  0.5), float3( 0.5, -0.5,  0.5),
        // -Y face
        float3(-0.5, -0.5, -0.5), float3( 0.5, -0.5, -0.5), float3( 0.5, -0.5,  0.5),
        float3(-0.5, -0.5, -0.5), float3( 0.5, -0.5,  0.5), float3(-0.5, -0.5,  0.5),
        // +Y face
        float3(-0.5,  0.5, -0.5), float3(-0.5,  0.5,  0.5), float3( 0.5,  0.5,  0.5),
        float3(-0.5,  0.5, -0.5), float3( 0.5,  0.5,  0.5), float3( 0.5,  0.5, -0.5)
    };

    float3 local = CubeVerts[vertexID];
    float4 worldPos = mul(float4(local, 1.0), DecalWorld);
    float4 clip = mul(worldPos, ViewProjectionMatrix);

    VertexOutput output;
    output.Position = clip;
    // Screen UV is recomputed in the fragment shader from SV_Position, so this
    // slot isn't strictly needed - but we keep it for clarity.
    output.ScreenUV = float2(0, 0);
    return output;
}
