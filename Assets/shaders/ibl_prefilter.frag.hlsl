// IBL Prefilter (GGX) - fragment shader half.
//
// One render pass per (probe slot, cubemap face, mip level): the pass renders
// a fullscreen triangle into a single-mip single-layer view of the prefiltered
// cubemap array slice. The fragment shader runs the same GGX importance-sample
// convolution as the compute version but writes via SV_Target instead of a
// storage image, which keeps the storage-image format declaration out of HLSL
// (DXC defaults `RWTexture2D<float4>` to rgba32f, mismatching the rgba16f view).
//
// Mip 0 of the cubemap is captured directly by ProbeCapturePass; mips 1..N are
// produced here with roughness = mip / (mipCount - 1).

#pragma pack_matrix(row_major)

cbuffer PrefilterParams : register(b0)
{
    uint  ProbeSlot;   // index into the probe array (cubemap layer = ProbeSlot*6 + FaceIndex)
    uint  FaceIndex;   // 0..5 (+X, -X, +Y, -Y, +Z, -Z)
    uint  MipLevel;    // output mip (1..MipCount-1)
    uint  MipCount;    // total mip levels in the chain
    uint  FaceSize;    // mip 0 face resolution
    uint  MipSize;     // this mip's face resolution = FaceSize >> MipLevel
    float Roughness;   // MipLevel / (MipCount - 1)
    uint  _Pad;
};

TextureCubeArray<float4> SourceCubemap : register(t0);
SamplerState             LinearSampler : register(s0);

static const uint NUM_SAMPLES = 64;

float RadicalInverseVdC(uint bits)
{
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    return float(bits) * 2.3283064365386963e-10;
}

float2 Hammersley(uint i, uint n)
{
    return float2(float(i) / float(n), RadicalInverseVdC(i));
}

float3 ImportanceSampleGGX(float2 Xi, float3 N, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;

    float phi = 2.0 * 3.14159265 * Xi.x;
    float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a2 - 1.0) * Xi.y));
    float sinTheta = sqrt(max(1.0 - cosTheta * cosTheta, 0.0));

    float3 Ht = float3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);

    float3 up = abs(N.z) < 0.999 ? float3(0, 0, 1) : float3(1, 0, 0);
    float3 T = normalize(cross(up, N));
    float3 B = cross(N, T);

    return normalize(T * Ht.x + B * Ht.y + N * Ht.z);
}

// Convert (face, normalized UV in [0,1]) to a world-space direction.
// Must match the convention used by ProbeCaptureView matrices and
// ibl_sh9_project.comp.hlsl.
float3 FaceUVToDirection(uint face, float2 uv)
{
    float2 c = uv * 2.0 - 1.0;
    float3 dir;
    switch (face)
    {
    case 0: dir = float3( 1.0, -c.y, -c.x); break;  // +X
    case 1: dir = float3(-1.0, -c.y,  c.x); break;  // -X
    case 2: dir = float3( c.x,  1.0,  c.y); break;  // +Y
    case 3: dir = float3( c.x, -1.0, -c.y); break;  // -Y
    case 4: dir = float3( c.x, -c.y,  1.0); break;  // +Z
    default:dir = float3(-c.x, -c.y, -1.0); break;  // -Z
    }
    return normalize(dir);
}

struct VertexOutput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
};

float4 main(VertexOutput input) : SV_Target0
{
    // The fullscreen vertex shader gives a Y-flipped UV (top-left origin).
    // Flip back so the face-UV convention here matches the compute / SH9 path.
    float2 uv = float2(input.TexCoord.x, 1.0 - input.TexCoord.y);

    float3 N = FaceUVToDirection(FaceIndex, uv);
    float3 V = N;  // split-sum approximation: V = N = R

    float totalWeight = 0.0;
    float3 prefilteredColor = float3(0, 0, 0);

    [loop]
    for (uint i = 0; i < NUM_SAMPLES; i++)
    {
        float2 Xi = Hammersley(i, NUM_SAMPLES);
        float3 H = ImportanceSampleGGX(Xi, N, Roughness);
        float3 L = normalize(2.0 * dot(V, H) * H - V);

        float NdotL = saturate(dot(N, L));
        if (NdotL > 0.0)
        {
            float3 c = SourceCubemap.SampleLevel(LinearSampler, float4(L, float(ProbeSlot)), 0).rgb;
            prefilteredColor += c * NdotL;
            totalWeight += NdotL;
        }
    }

    prefilteredColor /= max(totalWeight, 0.0001);
    return float4(prefilteredColor, 1.0);
}
