// Sample002_Textures: Shader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: vertex VSMain
// entry: fragment PSMain

Texture2D gTexture : register(t0, space0);
SamplerState gSampler : register(s0, space0);
struct VSInput { float3 Position : TEXCOORD0; float2 TexCoord : TEXCOORD1; };
struct PSInput { float4 Position : SV_POSITION; float2 TexCoord : TEXCOORD0; };
PSInput VSMain(VSInput input) {
    PSInput output;
    output.Position = float4(input.Position, 1.0);
    output.TexCoord = input.TexCoord;
    return output;
}
float4 PSMain(PSInput input) : SV_TARGET {
    return gTexture.Sample(gSampler, input.TexCoord);
}
