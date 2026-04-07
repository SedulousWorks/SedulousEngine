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

    // Apply exposure
    hdr *= Exposure;

    // Tone map
    float3 ldr = ACESFilmic(hdr);

    // Output linear — sRGB swapchain handles gamma correction
    return float4(ldr, 1.0);
}
