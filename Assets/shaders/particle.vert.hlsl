// Instanced particle billboard vertex shader.
// Each draw issues 6 vertices (2 triangles forming a quad) × N instances.
// Per-vertex: local corner picked by SV_VertexID.
// Per-instance: position, size, color, rotation, atlas UV, velocity (via
//               per-instance vertex attributes in buffer slot 0).
//
// Supports camera-facing billboards with per-particle rotation.
// Stretched billboards use Velocity2D to elongate along the velocity direction.

#pragma pack_matrix(row_major)

cbuffer SceneUniforms : register(b0, space0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
    float4x4 ViewProjectionMatrix;
    // ... rest not needed
};

struct VertexInput
{
    float3 WorldPos       : POSITION;     // world-space particle center
    float2 Size           : TEXCOORD0;    // billboard width, height
    float4 Color          : COLOR;        // RGBA tint (unorm8x4)
    float  Rotation       : TEXCOORD1;    // rotation angle in radians
    float4 UVOffsetScale  : TEXCOORD2;    // xy = atlas offset, zw = atlas scale
    float2 Velocity2D     : TEXCOORD3;    // screen-space velocity for stretched billboard
    uint   VertexID       : SV_VertexID;
};

struct VertexOutput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
    float4 Color    : COLOR0;
};

VertexOutput main(VertexInput input)
{
    // Triangle-list quad corners centered at (0,0).
    static const float2 LOCAL_CORNERS[6] = {
        float2(-0.5, -0.5),
        float2( 0.5, -0.5),
        float2(-0.5,  0.5),
        float2( 0.5, -0.5),
        float2( 0.5,  0.5),
        float2(-0.5,  0.5)
    };

    // UVs in [0,1] for each corner (y flipped for texture-space top-down).
    static const float2 LOCAL_UVS[6] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 1.0),
        float2(1.0, 0.0),
        float2(0.0, 0.0)
    };

    float2 local = LOCAL_CORNERS[input.VertexID];
    float2 localUV = LOCAL_UVS[input.VertexID];

    // Camera axes in world space (from row-major view matrix columns).
    float3 camRight = float3(ViewMatrix._m00, ViewMatrix._m10, ViewMatrix._m20);
    float3 camUp    = float3(ViewMatrix._m01, ViewMatrix._m11, ViewMatrix._m21);

    // Apply per-particle rotation around the camera forward axis.
    float cosR = cos(input.Rotation);
    float sinR = sin(input.Rotation);
    float3 right = camRight * cosR + camUp * sinR;
    float3 up    = camUp    * cosR - camRight * sinR;

    // Stretched billboard: elongate along the velocity direction.
    float velLen = length(input.Velocity2D);
    if (velLen > 0.001)
    {
        float2 velDir = input.Velocity2D / velLen;
        // Override right/up to align with velocity.
        // Stretch factor: longer quads for faster particles.
        float stretch = 1.0 + velLen * 0.1;
        float3 velRight = camRight * velDir.x + camUp * velDir.y;
        float3 velUp    = camUp    * velDir.x - camRight * velDir.y;
        right = velRight;
        up    = velUp;
        local.y *= stretch;
    }

    float3 cornerWS = input.WorldPos
                    + right * (local.x * input.Size.x)
                    + up    * (local.y * input.Size.y);

    VertexOutput output;
    output.Position = mul(float4(cornerWS, 1.0), ViewProjectionMatrix);

    // Atlas UV mapping: offset + localUV * scale.
    output.TexCoord = input.UVOffsetScale.xy + localUV * input.UVOffsetScale.zw;
    output.Color = input.Color;
    return output;
}
