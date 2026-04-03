// 2D Drawing fragment shader
// Samples RGBA texture and multiplies with vertex color

struct PSInput
{
    float4 position : SV_Position;
    float2 texCoord : TEXCOORD0;
    float4 color : COLOR0;
};

// Drawing texture (RGBA format) and sampler
Texture2D drawTexture : register(t0);
SamplerState drawSampler : register(s0);

float4 main(PSInput input) : SV_Target
{
    // Sample texture color
    float4 texColor = drawTexture.Sample(drawSampler, input.texCoord);

    // Multiply with vertex color
    return texColor * input.color;
}
