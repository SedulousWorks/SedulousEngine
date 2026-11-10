// Sample019_BatchUpload: Shader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: vertex VSMain
// entry: fragment PSMain

Texture2D gTexture : register(t0, space0);
SamplerState gSampler : register(s0, space0);

struct VSInput
{
    float3 Position : TEXCOORD0;
    float2 TexCoord : TEXCOORD1;
};

struct PSInput
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
};

cbuffer Transform : register(b0, space0)
{
    float Time;
    float Pad0;
    float Pad1;
    float Pad2;
};

PSInput VSMain(VSInput input)
{
    PSInput output;
    // Gentle rotation
    float c = cos(Time * 0.5);
    float s = sin(Time * 0.5);
    float3 p = input.Position;
    float x = p.x * c - p.y * s;
    float y = p.x * s + p.y * c;
    output.Position = float4(x, y, p.z, 1.0);
    output.TexCoord = input.TexCoord;
    return output;
}

float4 PSMain(PSInput input) : SV_TARGET
{
    return gTexture.Sample(gSampler, input.TexCoord);
}
