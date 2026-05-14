// Instanced particle billboard vertex shader.
// Each draw issues 6 vertices (2 triangles forming a quad) × N instances.
// Per-vertex: local corner picked by SV_VertexID.
// Per-instance: position, size, color, rotation, atlas UV, velocity (via
//               per-instance vertex attributes in buffer slot 0).
//
// Supports four orientation modes selected per-particle by RenderMode:
//   0: Billboard           - camera-facing, with per-particle rotation
//   1: StretchedBillboard  - elongated along velocity (implicit via Velocity2D)
//   2: HorizontalBillboard - XZ plane, normal = +Y (ground decals, dust)
//   3: VerticalBillboard   - Y-up locked, faces camera horizontally (grass, fire)
//   4: Mesh   - not handled here; separate draw path
//   5: Trail  - not handled here; separate trail shader
//
// StretchedBillboard is detected by the extractor only setting Velocity2D
// for that mode; the branch in this shader is gated on `length(Velocity2D)`
// so it overrides the explicit RenderMode if present.

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
    float3 WorldPos       : TEXCOORD0;    // world-space particle center
    float2 Size           : TEXCOORD1;    // billboard width, height
    float4 Color          : TEXCOORD2;    // RGBA tint (unorm8x4)
    float  Rotation       : TEXCOORD3;    // rotation angle in radians
    float4 UVOffsetScale  : TEXCOORD4;    // xy = atlas offset, zw = atlas scale
    float2 Velocity2D     : TEXCOORD5;    // screen-space velocity for stretched billboard
    uint   RenderMode     : TEXCOORD6;    // per-particle orientation mode
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

    float cosR = cos(input.Rotation);
    float sinR = sin(input.Rotation);

    // Pick basis. StretchedBillboard wins if Velocity2D is set, otherwise
    // dispatch on RenderMode. Default falls back to camera-facing billboard.
    float3 right;
    float3 up;

    float velLen = length(input.Velocity2D);
    if (velLen > 0.001)
    {
        // StretchedBillboard: elongate along velocity direction.
        float2 velDir = input.Velocity2D / velLen;
        right = camRight * velDir.x + camUp * velDir.y;
        up    = camUp    * velDir.x - camRight * velDir.y;
        // Stretch factor: longer quads for faster particles.
        float stretch = 1.0 + velLen * 0.1;
        local.y *= stretch;
    }
    else if (input.RenderMode == 2u)
    {
        // HorizontalBillboard: quad lies in the XZ plane (normal = +Y).
        // Per-particle rotation spins around the Y normal.
        right = float3( cosR, 0.0,  sinR);
        up    = float3(-sinR, 0.0,  cosR);
    }
    else if (input.RenderMode == 3u)
    {
        // VerticalBillboard: up is world +Y, right is horizontal-camera-facing.
        // Per-particle rotation is intentionally not applied - this mode
        // exists for grass/flame sprites that want a fixed vertical axis.
        float3 camForward = -float3(ViewMatrix._m02, ViewMatrix._m12, ViewMatrix._m22);
        camForward.y = 0.0;
        float3 worldUp = float3(0.0, 1.0, 0.0);
        // If camera is looking straight down/up, camForward.xz collapses;
        // fall back to world X to keep right finite.
        float horizLen = length(camForward);
        camForward = (horizLen > 0.001) ? (camForward / horizLen) : float3(0.0, 0.0, 1.0);
        right = normalize(cross(worldUp, camForward));
        up    = worldUp;
    }
    else
    {
        // Billboard (default): camera-facing with per-particle rotation.
        right = camRight * cosR + camUp * sinR;
        up    = camUp    * cosR - camRight * sinR;
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
