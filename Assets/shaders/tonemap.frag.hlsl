// Tonemap Fragment Shader
// ACES filmic tone mapping + gamma correction.
// Reads HDR scene color and optional bloom texture.

cbuffer TonemapParams : register(b0)
{
    float Exposure;
    float WhitePoint;
    float Gamma;
    float _Pad;
};

Texture2D SceneColor : register(t0);
Texture2D BloomTexture : register(t1);
Texture2D AOTexture : register(t2);
Texture2D SSRTexture : register(t3);
SamplerState LinearSampler : register(s0);

struct FragmentInput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
};

// ACES filmic tone mapping curve
// Attempt to approximate the Academy Color Encoding System
float3 ACESFilmic(float3 x)
{
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
}

float4 main(FragmentInput input) : SV_Target
{
    float2 uv = input.TexCoord;

    float3 hdr = SceneColor.Sample(LinearSampler, uv).rgb;

    // Apply SSAO: multiply by ambient occlusion factor before bloom/tonemap.
    // AOTexture is R8 where 1.0 = no occlusion, 0.0 = fully occluded.
    // When SSAO is disabled, the fallback is a white (1.0) texture - no darkening.
    float ao = AOTexture.Sample(LinearSampler, uv).r;
    hdr *= ao;

    // Apply SSR: blend in screen-space reflections.
    // SSRTexture is RGBA16F where rgb = reflection color, a = confidence mask.
    // When SSR is disabled, the fallback black texture (rgb=0) adds nothing.
    float4 ssr = SSRTexture.Sample(LinearSampler, uv);
    hdr += ssr.rgb * ssr.a;

    // DEBUG: uncomment to visualize SSR confidence as red overlay
    //return float4(ssr.a, ssr.a, ssr.a, 1.0);
    // DEBUG: uncomment to visualize raw SSR output
    //return float4(ssr.rgb, 1.0);

    // Add bloom contribution.
    float3 bloom = BloomTexture.Sample(LinearSampler, uv).rgb;
    hdr += bloom;

    // Apply exposure
    hdr *= Exposure;

    // Tone map
    float3 ldr = ACESFilmic(hdr);

    // Output linear - sRGB swapchain handles gamma correction
    return float4(ldr, 1.0);
}
