// Sample022_StencilOutline: Shader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: vertex VSMain
// entry: fragment PSMain

struct PushConstants
{
    float Scale;
    float AspectRatio;
    float Time;
    float _pad;
};

[[vk::push_constant]] ConstantBuffer<PushConstants> pc : register(b0, space0);

struct VSInput
{
    float3 Position : TEXCOORD0;
    float4 Color    : TEXCOORD1;
};

struct PSInput
{
    float4 Position : SV_POSITION;
    float4 Color    : COLOR0;
};

PSInput VSMain(VSInput input)
{
    PSInput output;
    float2 pos = input.Position.xy * pc.Scale;
    pos.x /= pc.AspectRatio;
    // Gentle rotation
    float c = cos(pc.Time * 0.5);
    float s = sin(pc.Time * 0.5);
    float2 rotated = float2(pos.x * c - pos.y * s, pos.x * s + pos.y * c);
    output.Position = float4(rotated, input.Position.z, 1.0);
    output.Color = input.Color;
    return output;
}

float4 PSMain(PSInput input) : SV_TARGET
{
    return input.Color;
}
