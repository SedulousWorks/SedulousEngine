// Prefilter Convolution Fragment Shader
// Generates one face of a specular prefilter cubemap at a given roughness level.
// Uses GGX importance sampling for the split-sum approximation.
// Use with fullscreen.vert.hlsl. Set FaceIndex and Roughness via params cbuffer.
// Dispatch once per mip level with roughness = mip / (mipCount - 1).

#pragma pack_matrix(row_major)

static const float PI = 3.14159265359;
static const uint SAMPLE_COUNT = 1024;

cbuffer Params : register(b0)
{
    uint FaceIndex;   // 0=+X, 1=-X, 2=+Y, 3=-Y, 4=+Z, 5=-Z
    float Roughness;  // 0.0 (mirror) to 1.0 (fully rough)
    uint _Pad0;
    uint _Pad1;
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

// Van der Corput radical inverse for Hammersley sequence
float RadicalInverse_VdC(uint bits)
{
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    return float(bits) * 2.3283064365386963e-10;
}

float2 Hammersley(uint i, uint N)
{
    return float2(float(i) / float(N), RadicalInverse_VdC(i));
}

// GGX importance sampling: generates a half-vector H distributed according to
// the GGX NDF for the given roughness, in tangent space around N.
float3 ImportanceSampleGGX(float2 Xi, float3 N, float roughness)
{
    float a = roughness * roughness;

    float phi = 2.0 * PI * Xi.x;
    float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a * a - 1.0) * Xi.y));
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

    // Spherical to Cartesian (tangent space)
    float3 H;
    H.x = cos(phi) * sinTheta;
    H.y = sin(phi) * sinTheta;
    H.z = cosTheta;

    // Build tangent frame from N
    float3 up = abs(N.y) < 0.999 ? float3(0, 1, 0) : float3(1, 0, 0);
    float3 tangent = normalize(cross(up, N));
    float3 bitangent = cross(N, tangent);

    // Tangent space to world space
    return normalize(tangent * H.x + bitangent * H.y + N * H.z);
}

float4 main(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target0
{
    float3 N = CubeUVToDirection(uv, FaceIndex);
    // Split-sum approximation assumes V = R = N
    float3 R = N;
    float3 V = R;

    float3 prefilteredColor = 0.0;
    float totalWeight = 0.0;

    for (uint i = 0; i < SAMPLE_COUNT; i++)
    {
        float2 Xi = Hammersley(i, SAMPLE_COUNT);
        float3 H = ImportanceSampleGGX(Xi, N, Roughness);
        float3 L = normalize(2.0 * dot(V, H) * H - V);

        float NdotL = max(dot(N, L), 0.0);
        if (NdotL > 0.0)
        {
            prefilteredColor += EnvironmentMap.SampleLevel(LinearSampler, L, 0).rgb * NdotL;
            totalWeight += NdotL;
        }
    }

    prefilteredColor /= max(totalWeight, 0.001);

    return float4(prefilteredColor, 1.0);
}
