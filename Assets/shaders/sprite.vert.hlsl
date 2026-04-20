// Instanced sprite vertex shader.
// Each draw issues 6 vertices (2 triangles forming a quad) × N instances.
// Per-vertex: local corner picked by SV_VertexID.
// Per-instance: position, size, color, UV rect, orientation mode (via
//               per-instance vertex attributes in buffer slot 0).
//
// Orientation modes:
//   0 = CameraFacing   - quad basis = (camera right, camera up)
//   1 = CameraFacingY  - quad basis = (camera right projected into XZ, world Y)
//   2 = WorldAligned   - quad basis = (world X, world Y)

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
    float4 PositionSize    : POSITION;    // xyz = world pos, w = size.x
    float4 SizeOrientation : TEXCOORD0;   // x = size.y, y = orientation mode
    float4 Tint            : COLOR;
    float4 UVRect          : TEXCOORD1;   // (u, v, w, h)
    uint   VertexID        : SV_VertexID;
};

struct VertexOutput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
    float4 Color    : COLOR0;
};

VertexOutput main(VertexInput input)
{
    // Triangle-list quad corners in local sprite space, centered at (0,0).
    // CW winding when viewed from +Z (which matches CCW front-face convention
    // on the camera-facing path since the basis is flipped in view space).
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

    float3 worldPos = input.PositionSize.xyz;
    float2 size = float2(input.PositionSize.w, input.SizeOrientation.x);
    int orientation = (int)input.SizeOrientation.y;

    // Camera axes in world space come from the VIEW matrix's columns (in row-
    // major storage that's ._m00/_m10/_m20 for the right vector).
    float3 camRight = float3(ViewMatrix._m00, ViewMatrix._m10, ViewMatrix._m20);
    float3 camUp    = float3(ViewMatrix._m01, ViewMatrix._m11, ViewMatrix._m21);

    float3 right;
    float3 up;
    if (orientation == 1) // CameraFacingY
    {
        float3 flatRight = float3(camRight.x, 0.0, camRight.z);
        float len = length(flatRight);
        right = len > 0.0001 ? flatRight / len : float3(1, 0, 0);
        up = float3(0, 1, 0);
    }
    else if (orientation == 2) // WorldAligned
    {
        right = float3(1, 0, 0);
        up    = float3(0, 1, 0);
    }
    else // CameraFacing (default)
    {
        right = camRight;
        up    = camUp;
    }

    float3 cornerWS = worldPos
                    + right * (local.x * size.x)
                    + up    * (local.y * size.y);

    VertexOutput output;
    output.Position = mul(float4(cornerWS, 1.0), ViewProjectionMatrix);
    output.TexCoord = input.UVRect.xy + localUV * input.UVRect.zw;
    output.Color = input.Tint;
    return output;
}
