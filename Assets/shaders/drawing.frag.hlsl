// 2D Drawing Fragment Shader
// Samples texture and multiplies with vertex color

struct PSInput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR0;
};

Texture2D DrawTexture : register(t0);
SamplerState DrawSampler : register(s0);

float4 main(PSInput input) : SV_Target
{
    float4 texColor = DrawTexture.Sample(DrawSampler, input.TexCoord);
    return texColor * input.Color;
}
