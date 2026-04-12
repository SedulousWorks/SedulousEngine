// Bloom downsample fragment shader.
//
// Progressive 2× downsample with a 13-tap filter (Jimenez 2014 — Call of Duty
// method). Produces a smooth half-res output from the input texture. On the
// first pass (MipLevel == 0) a brightness threshold is applied so only pixels
// above the threshold contribute to the bloom.
//
// Uses the same fullscreen-triangle vertex shader as tonemap (tonemap.vert.hlsl).

cbuffer BloomParams : register(b0)
{
    float Threshold;     // brightness cutoff for the extract pass
    float Intensity;     // bloom strength (used in upsample, ignored here)
    int   MipLevel;      // 0 = first pass (applies threshold), > 0 = subsequent
    float _Pad;
};

Texture2D    SourceTexture : register(t0);
SamplerState LinearSampler : register(s0);

struct FragmentInput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
};

// Luminance (BT.709) for thresholding.
float Luminance(float3 c) { return dot(c, float3(0.2126, 0.7152, 0.0722)); }

// Soft knee threshold — avoids the hard cutoff that causes flickering on
// pixels near the boundary. Returns a smooth 0..1 weight.
float3 ThresholdColor(float3 color)
{
    float brightness = Luminance(color);
    float knee = Threshold * 0.5; // soft knee width
    float soft = brightness - Threshold + knee;
    soft = clamp(soft, 0.0, 2.0 * knee);
    soft = soft * soft / (4.0 * knee + 0.00001);
    float contribution = max(soft, brightness - Threshold) / max(brightness, 0.00001);
    return color * max(contribution, 0.0);
}

float4 main(FragmentInput input) : SV_Target
{
    float2 uv = input.TexCoord;
    float2 texelSize;
    SourceTexture.GetDimensions(texelSize.x, texelSize.y);
    texelSize = 1.0 / texelSize;

    // 13-tap downsample filter (Jimenez 2014).
    // Weighted box filter that reduces aliasing compared to a naive 4-tap.
    //
    //   a - b - c
    //   - j - k -
    //   d - e - f
    //   - l - m -
    //   g - h - i
    //
    float3 a = SourceTexture.Sample(LinearSampler, uv + float2(-1, -1) * texelSize).rgb;
    float3 b = SourceTexture.Sample(LinearSampler, uv + float2( 0, -1) * texelSize).rgb;
    float3 c = SourceTexture.Sample(LinearSampler, uv + float2( 1, -1) * texelSize).rgb;
    float3 d = SourceTexture.Sample(LinearSampler, uv + float2(-1,  0) * texelSize).rgb;
    float3 e = SourceTexture.Sample(LinearSampler, uv).rgb;
    float3 f = SourceTexture.Sample(LinearSampler, uv + float2( 1,  0) * texelSize).rgb;
    float3 g = SourceTexture.Sample(LinearSampler, uv + float2(-1,  1) * texelSize).rgb;
    float3 h = SourceTexture.Sample(LinearSampler, uv + float2( 0,  1) * texelSize).rgb;
    float3 i = SourceTexture.Sample(LinearSampler, uv + float2( 1,  1) * texelSize).rgb;
    float3 j = SourceTexture.Sample(LinearSampler, uv + float2(-0.5, -0.5) * texelSize).rgb;
    float3 k = SourceTexture.Sample(LinearSampler, uv + float2( 0.5, -0.5) * texelSize).rgb;
    float3 l = SourceTexture.Sample(LinearSampler, uv + float2(-0.5,  0.5) * texelSize).rgb;
    float3 m = SourceTexture.Sample(LinearSampler, uv + float2( 0.5,  0.5) * texelSize).rgb;

    // Weighted combination: center 4-tap gets half the weight,
    // corner groups share the rest.
    float3 color = e * 0.125;
    color += (a + c + g + i) * 0.03125;
    color += (b + d + f + h) * 0.0625;
    color += (j + k + l + m) * 0.125;

    // Apply brightness threshold on the first downsample pass only.
    if (MipLevel == 0)
        color = ThresholdColor(color);

    return float4(color, 1.0);
}
