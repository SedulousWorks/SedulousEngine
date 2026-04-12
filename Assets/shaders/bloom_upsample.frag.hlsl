// Bloom upsample fragment shader.
//
// Progressive 2× upsample with a 9-tap tent filter. Reads the lower-resolution
// bloom mip and blends it additively with the current-resolution level from the
// downsample chain. Produces a progressively wider, softer bloom at each step.
//
// Uses the same fullscreen-triangle vertex shader as tonemap (tonemap.vert.hlsl).

cbuffer BloomParams : register(b0)
{
    float Threshold;     // unused in upsample
    float Intensity;     // final bloom strength multiplier
    int   MipLevel;      // current upsample level (for debugging)
    float _Pad;
};

Texture2D    LowerMip     : register(t0);  // lower-res bloom from previous upsample (or bottom of downsample chain)
Texture2D    CurrentLevel : register(t1);  // current-res downsample level to blend with
SamplerState LinearSampler : register(s0);

struct FragmentInput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
};

float4 main(FragmentInput input) : SV_Target
{
    float2 uv = input.TexCoord;
    float2 texelSize;
    LowerMip.GetDimensions(texelSize.x, texelSize.y);
    texelSize = 1.0 / texelSize;

    // 9-tap tent filter for smooth upsampling.
    //   1 2 1
    //   2 4 2  (weights sum to 16)
    //   1 2 1
    float3 bloom = 0.0;
    bloom += LowerMip.Sample(LinearSampler, uv + float2(-1, -1) * texelSize).rgb * 1.0;
    bloom += LowerMip.Sample(LinearSampler, uv + float2( 0, -1) * texelSize).rgb * 2.0;
    bloom += LowerMip.Sample(LinearSampler, uv + float2( 1, -1) * texelSize).rgb * 1.0;
    bloom += LowerMip.Sample(LinearSampler, uv + float2(-1,  0) * texelSize).rgb * 2.0;
    bloom += LowerMip.Sample(LinearSampler, uv                              ).rgb * 4.0;
    bloom += LowerMip.Sample(LinearSampler, uv + float2( 1,  0) * texelSize).rgb * 2.0;
    bloom += LowerMip.Sample(LinearSampler, uv + float2(-1,  1) * texelSize).rgb * 1.0;
    bloom += LowerMip.Sample(LinearSampler, uv + float2( 0,  1) * texelSize).rgb * 2.0;
    bloom += LowerMip.Sample(LinearSampler, uv + float2( 1,  1) * texelSize).rgb * 1.0;
    bloom /= 16.0;

    // Blend with the corresponding downsample level.
    float3 current = CurrentLevel.Sample(LinearSampler, uv).rgb;

    return float4(bloom + current, 1.0);
}
