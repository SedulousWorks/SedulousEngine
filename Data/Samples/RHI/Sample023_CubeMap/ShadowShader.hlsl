// Sample023_CubeMap: ShadowShader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: vertex VSMain
// entry: fragment PSMain

Texture2D<float> gShadowMap : register(t0, space0);
SamplerComparisonState gShadowSampler : register(s0, space0);

struct PushConstants
{
    float Time;
    float AspectRatio;
    float2 _pad;
};

[[vk::push_constant]] ConstantBuffer<PushConstants> pc : register(b0, space1);

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

PSInput VSMain(VSInput input)
{
    PSInput output;
    output.Position = float4(input.Position, 1.0);
    output.TexCoord = input.TexCoord;
    return output;
}

float4 PSMain(PSInput input) : SV_TARGET
{
    // Compare at varying depth based on time for animated shadow boundary
    float compareValue = 0.5 + 0.4 * sin(pc.Time);
    float shadow = gShadowMap.SampleCmpLevelZero(gShadowSampler, input.TexCoord, compareValue);
    float3 litColor = float3(0.9, 0.85, 0.7);
    float3 shadowColor = float3(0.1, 0.1, 0.2);
    float3 color = lerp(shadowColor, litColor, shadow);
    return float4(color, 1.0);
}
