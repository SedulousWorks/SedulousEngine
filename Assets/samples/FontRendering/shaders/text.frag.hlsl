// Text rendering fragment shader
// Samples R8 font atlas and applies vertex color

struct PSInput
{
    float4 position : SV_Position;
    float2 texCoord : TEXCOORD0;
    float4 color : COLOR0;
};

// Font atlas texture (R8 format) and sampler
Texture2D fontTexture : register(t0);
SamplerState fontSampler : register(s0);

float4 main(PSInput input) : SV_Target
{
    // Sample alpha from font atlas (R channel)
    float alpha = fontTexture.Sample(fontSampler, input.texCoord).r;

    // Apply vertex color with sampled alpha
    return float4(input.color.rgb, input.color.a * alpha);
}
