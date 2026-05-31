// Equirectangular to Cubemap Face Fragment Shader
// Renders one cubemap face per pass. Use with fullscreen.vert.hlsl.
// Set FaceIndex via the params cbuffer before each draw.

#pragma pack_matrix(row_major)

static const float PI = 3.14159265359;

cbuffer Params : register(b0)
{
    uint FaceIndex;  // 0=+X, 1=-X, 2=+Y, 3=-Y, 4=+Z, 5=-Z
    uint _Pad0;
    uint _Pad1;
    uint _Pad2;
};

Texture2D<float4> EquirectMap : register(t0);
SamplerState LinearSampler : register(s0);

// Convert cubemap face UV + face index to a world-space direction.
float3 CubeUVToDirection(float2 uv, uint face)
{
    float u = uv.x * 2.0 - 1.0;
    float v = uv.y * 2.0 - 1.0;

    switch (face)
    {
        case 0: return normalize(float3( 1.0,   -v,   -u)); // +X
        case 1: return normalize(float3(-1.0,   -v,    u)); // -X
        case 2: return normalize(float3(   u,  1.0,    v)); // +Y
        case 3: return normalize(float3(   u, -1.0,   -v)); // -Y
        case 4: return normalize(float3(   u,   -v,  1.0)); // +Z
        case 5: return normalize(float3(  -u,   -v, -1.0)); // -Z
        default: return float3(0, 0, 1);
    }
}

float2 DirectionToEquirectangular(float3 dir)
{
    float phi = atan2(dir.z, dir.x);
    float theta = asin(dir.y);
    float u = phi / (2.0 * PI) + 0.5;
    float v = theta / PI + 0.5;
    return float2(u, 1.0 - v);
}

float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target0
{
    float3 dir = CubeUVToDirection(uv, FaceIndex);
    float2 equirectUV = DirectionToEquirectangular(dir);
    return EquirectMap.SampleLevel(LinearSampler, equirectUV, 0);
}
