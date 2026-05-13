// TAA Resolve Fragment Shader
// Temporal Anti-Aliasing: blends current jittered frame with reprojected history.
// Runs in HDR before tone mapping. See CONVENTIONS.md for shader rules.

#pragma pack_matrix(row_major)

cbuffer TAAParams : register(b0)
{
    float2 TexelSize;          // 1.0 / screenSize
    float BlendFactor;         // base history weight (0.95 = default)
    float HistoryValid;        // 0.0 = no valid history (first frame), 1.0 = valid
    float2 JitterOffset;       // current frame's jitter in clip space
    float2 PrevJitterOffset;   // previous frame's jitter in clip space
};

Texture2D CurrentColor : register(t0);
Texture2D HistoryColor : register(t1);
Texture2D MotionVectors : register(t2);
Texture2D DepthTexture : register(t3);
SamplerState PointSampler : register(s0);
SamplerState LinearSampler : register(s1);

struct FragmentInput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
};

struct FragmentOutput
{
    float4 Color : SV_Target0;   // Post-process chain output
    float4 History : SV_Target1; // History buffer for next frame
};

float Luminance(float3 c)
{
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

// Tone-weight a sample by 1/(1+luma) so bright HDR outliers carry less
// weight in the AABB neighborhood and the resolve blend (Karis 2014 /
// "High-Quality Temporal Supersampling"). Without this, single-frame
// specular spikes blow up the box and leak through the clip every frame.
float3 ToneWeight(float3 c)
{
    return c / (1.0 + Luminance(c));
}

float3 InverseToneWeight(float3 c)
{
    return c / max(1.0 - Luminance(c), 1e-5);
}

// Clip color toward AABB center instead of hard clamping.
// Produces smoother results at AABB boundaries (Pedersen 2016, INSIDE).
float3 ClipToAABB(float3 color, float3 aabbMin, float3 aabbMax)
{
    float3 center = (aabbMax + aabbMin) * 0.5;
    float3 extents = (aabbMax - aabbMin) * 0.5;
    float3 shift = color - center;
    float3 absUnit = abs(shift / max(extents, 0.0001));
    float maxUnit = max(max(absUnit.x, absUnit.y), absUnit.z);
    return maxUnit > 1.0 ? center + (shift / maxUnit) : color;
}

FragmentOutput main(FragmentInput input)
{
    float2 uv = input.TexCoord;

    // Sample current color
    float3 current = CurrentColor.Sample(PointSampler, uv).rgb;

    // Find closest depth in 3x3 neighborhood for stable motion vector selection.
    float closestDepth = 1.0;
    float2 closestUV = uv;

    for (int y = -1; y <= 1; y++)
    {
        for (int x = -1; x <= 1; x++)
        {
            float2 sampleUV = uv + float2(x, y) * TexelSize;
            float d = DepthTexture.Sample(PointSampler, sampleUV).r;
            if (d < closestDepth)
            {
                closestDepth = d;
                closestUV = sampleUV;
            }
        }
    }

    // Sample motion vector at closest-depth position and reproject
    float2 motion = MotionVectors.Sample(PointSampler, closestUV).rg;
    float2 historyUV = uv - motion;

    // Reject history if out of bounds or first frame
    if (HistoryValid < 0.5 ||
        any(historyUV < 0.0) || any(historyUV > 1.0))
    {
        FragmentOutput rejected;
        rejected.Color = float4(current, 1.0);
        rejected.History = float4(current, 1.0);
        return rejected;
    }

    // Sample history
    float3 history = HistoryColor.Sample(LinearSampler, historyUV).rgb;

    // Tone-weight every sample so HDR fireflies (single-frame specular spikes)
    // don't blow up the AABB or dominate the blend. Without this the box clip
    // is effectively a no-op on bright pixels and they shimmer through the
    // resolve every frame.
    float3 currentW = ToneWeight(current);
    float3 historyW = ToneWeight(history);

    // 3x3 neighborhood min/max in tone-weighted space for box clamping.
    float3 neighborMin = currentW;
    float3 neighborMax = currentW;

    for (int ny = -1; ny <= 1; ny++)
    {
        for (int nx = -1; nx <= 1; nx++)
        {
            if (nx == 0 && ny == 0) continue;
            float3 s = CurrentColor.Sample(PointSampler, uv + float2(nx, ny) * TexelSize).rgb;
            float3 sW = ToneWeight(s);
            neighborMin = min(neighborMin, sW);
            neighborMax = max(neighborMax, sW);
        }
    }

    // Clip history (weighted) to neighborhood AABB (soft clip toward center).
    historyW = ClipToAABB(historyW, neighborMin, neighborMax);

    // Luminance-adaptive blend factor (Lumix approach):
    // When current and history luminance match closely -> high blend (stable).
    // When they differ (specular flash, disocclusion) -> low blend (responsive).
    // Computed in tone-weighted space so a single specular spike doesn't
    // skew the adaptation as aggressively.
    float lum0 = Luminance(currentW);
    float lum1 = Luminance(historyW);
    float lumaDiff = 1.0 - abs(lum0 - lum1) / max(lum0, max(lum1, 0.1));
    float blend = lerp(0.85, BlendFactor, saturate(lumaDiff * lumaDiff));

    // Blend in tone-weighted space, then expand back to linear HDR.
    float3 resultW = lerp(currentW, historyW, blend);
    float3 result = InverseToneWeight(resultW);

    FragmentOutput output;
    output.Color = float4(result, 1.0);
    output.History = float4(result, 1.0);
    return output;
}
