// Sample007_Instancing: Shader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: vertex VSMain
// entry: fragment PSMain

struct VSInput
{
    float3 Position  : TEXCOORD0;
    float2 Offset    : TEXCOORD1;
    float4 InstColor : TEXCOORD2;
};
struct PSInput
{
    float4 Position : SV_POSITION;
    float4 Color    : COLOR0;
};
PSInput VSMain(VSInput input)
{
    PSInput output;
    output.Position = float4(input.Position.xy + input.Offset, input.Position.z, 1.0);
    output.Color = input.InstColor;
    return output;
}
float4 PSMain(PSInput input) : SV_TARGET
{
    return input.Color;
}
