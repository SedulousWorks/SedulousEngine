// IBL SH9 Projection - projects a captured cubemap (one probe) onto the first
// 9 spherical harmonic basis functions (l = 0, 1, 2), pre-convolved with the
// Lambertian (cos theta) kernel so the runtime lookup is:
//     irradiance(N) = sum_j coeff[j] * Y_j(N)
// without per-fragment band weights.
//
// Strategy: one thread group per probe. 64 threads sample the cubemap at a
// coarse mip (low frequency content is what SH9 captures anyway), each thread
// accumulates a partial set of 9 RGB coefficients, then a parallel reduction
// in groupshared memory sums them. Thread 0 writes the 9 final float4 entries
// at OutputSH9[probeSlot * 9 .. probeSlot * 9 + 8].

#pragma pack_matrix(row_major)

cbuffer SH9Params : register(b0)
{
    uint ProbeSlot;     // index into the probe array
    uint MipLevel;      // mip level to sample (high mip = pre-blurred; SH9 is low-freq)
    uint MipFaceSize;   // face resolution at MipLevel (= FaceSize >> MipLevel)
    uint _Pad;
};

TextureCubeArray<float4>   SourceCubemap : register(t0);
RWStructuredBuffer<float4> OutputSH9     : register(u0);
SamplerState               LinearSampler : register(s0);

static const uint THREAD_COUNT = 64;
groupshared float3 g_sh[9][THREAD_COUNT];

// Convert (face, normalized UV in [0,1]) to world-space direction.
// Must match the convention used by ibl_prefilter.comp.hlsl and the
// ProbeCaptureView matrix builder.
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

[numthreads(THREAD_COUNT, 1, 1)]
void main(uint3 dtid : SV_DispatchThreadID, uint3 gtid : SV_GroupThreadID)
{
    uint threadIdx = gtid.x;

    float3 local[9];
    for (uint j = 0; j < 9; j++) local[j] = float3(0, 0, 0);

    uint faceTexels   = MipFaceSize * MipFaceSize;
    uint totalSamples = 6u * faceTexels;
    // Ceil-divide so trailing threads handle the partial chunk.
    uint samplesPerThread = (totalSamples + THREAD_COUNT - 1u) / THREAD_COUNT;

    for (uint s = 0; s < samplesPerThread; s++)
    {
        uint sample = threadIdx + s * THREAD_COUNT;
        if (sample >= totalSamples) break;

        uint face  = sample / faceTexels;
        uint texel = sample % faceTexels;
        uint y     = texel / MipFaceSize;
        uint x     = texel % MipFaceSize;

        float2 uv = (float2(x, y) + 0.5) / float(MipFaceSize);
        float2 c  = uv * 2.0 - 1.0;
        float3 dir = FaceUVToDirection(face, uv);

        // Cubemap texel solid angle: dω = (4 / size^2) * (1 + u² + v²)^(-3/2)
        float r2 = 1.0 + c.x * c.x + c.y * c.y;
        float solidAngle = (4.0 / float(faceTexels)) * pow(r2, -1.5);

        // Sample the cubemap at the chosen mip for this probe slot.
        float3 color = SourceCubemap
            .SampleLevel(LinearSampler, float4(dir, float(ProbeSlot)), float(MipLevel)).rgb;

        // SH9 basis at this direction.
        float bx = dir.x, by = dir.y, bz = dir.z;
        float Y[9] = {
            0.282095,                            // Y(0,  0)
            0.488603 * by,                       // Y(1, -1)
            0.488603 * bz,                       // Y(1,  0)
            0.488603 * bx,                       // Y(1,  1)
            1.092548 * bx * by,                  // Y(2, -2)
            1.092548 * by * bz,                  // Y(2, -1)
            0.315392 * (3.0 * bz * bz - 1.0),    // Y(2,  0)
            1.092548 * bx * bz,                  // Y(2,  1)
            0.546274 * (bx * bx - by * by)       // Y(2,  2)
        };

        float3 weighted = color * solidAngle;
        for (uint j = 0; j < 9; j++)
            local[j] += weighted * Y[j];
    }

    for (uint j = 0; j < 9; j++)
        g_sh[j][threadIdx] = local[j];

    GroupMemoryBarrierWithGroupSync();

    // Parallel reduction. THREAD_COUNT must be a power of two.
    for (uint stride = THREAD_COUNT / 2u; stride > 0u; stride >>= 1u)
    {
        if (threadIdx < stride)
        {
            for (uint j = 0; j < 9; j++)
                g_sh[j][threadIdx] += g_sh[j][threadIdx + stride];
        }
        GroupMemoryBarrierWithGroupSync();
    }

    if (threadIdx == 0)
    {
        // Pre-convolve with the Lambertian cosine kernel so runtime lookup
        // is a direct sum (no band weights at evaluation time).
        // Per Ramamoorthi & Hanrahan: A_0 = π, A_1 = 2π/3, A_2 = π/4.
        const float PI = 3.141592653589793;
        const float A0 = PI;
        const float A1 = 2.0 * PI / 3.0;
        const float A2 = PI / 4.0;
        float W[9] = { A0, A1, A1, A1, A2, A2, A2, A2, A2 };

        for (uint j = 0; j < 9; j++)
            OutputSH9[ProbeSlot * 9u + j] = float4(g_sh[j][0] * W[j], 0.0);
    }
}
