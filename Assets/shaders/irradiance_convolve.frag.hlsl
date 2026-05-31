// Irradiance Convolution Fragment Shader
// Generates one face of a diffuse irradiance cubemap by convolving the
// environment cubemap with a cosine-weighted hemisphere integral.
// Use with fullscreen.vert.hlsl. Set FaceIndex via params cbuffer.

#pragma pack_matrix(row_major)

static const float PI = 3.14159265359;

cbuffer Params : register(b0)
{
    uint FaceIndex;  // 0=+X, 1=-X, 2=+Y, 3=-Y, 4=+Z, 5=-Z
    uint _Pad0;
    uint _Pad1;
    uint _Pad2;
};

TextureCube<float4> EnvironmentMap : register(t0);
SamplerState LinearSampler : register(s0);

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

float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target0
{
    float3 normal = CubeUVToDirection(uv, FaceIndex);

    // Build tangent frame from normal
    float3 up = abs(normal.y) < 0.999 ? float3(0, 1, 0) : float3(1, 0, 0);
    float3 tangent = normalize(cross(up, normal));
    float3 bitangent = cross(normal, tangent);

    // Cosine-weighted hemisphere sampling
    float3 irradiance = 0.0;
    float sampleCount = 0.0;

    static const float sampleDelta = 0.025;
    for (float phi = 0.0; phi < 2.0 * PI; phi += sampleDelta)
    {
        for (float theta = 0.0; theta < 0.5 * PI; theta += sampleDelta)
        {
            float sinTheta = sin(theta);
            float cosTheta = cos(theta);
            float3 tangentSample = float3(sinTheta * cos(phi), sinTheta * sin(phi), cosTheta);

            float3 sampleDir = tangentSample.x * tangent + tangentSample.y * bitangent + tangentSample.z * normal;

            irradiance += EnvironmentMap.SampleLevel(LinearSampler, sampleDir, 0).rgb * cosTheta * sinTheta;
            sampleCount += 1.0;
        }
    }

    irradiance = PI * irradiance / max(sampleCount, 1.0);

    return float4(irradiance, 1.0);
}
