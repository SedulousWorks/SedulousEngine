// Sample026_DynamicOffsets: Shader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: vertex VSMain
// entry: fragment PSMain

cbuffer ObjectData : register(b0, space0)
{
    float4 TintColor;
    float4 OffsetScale; // xy=offset, zw=scale
};

struct VSInput
{
    float3 Position : TEXCOORD0;
};

struct PSInput
{
    float4 Position : SV_POSITION;
};

PSInput VSMain(VSInput input)
{
    PSInput output;
    float2 pos = input.Position.xy * OffsetScale.zw + OffsetScale.xy;
    output.Position = float4(pos, input.Position.z, 1.0);
    return output;
}

float4 PSMain(PSInput input) : SV_TARGET
{
    return TintColor;
}
