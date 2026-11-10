// Sample020_MeshShaders: FragmentShader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: fragment PSMain

struct PSInput
{
    float4 Position : SV_POSITION;
    float3 Color    : TEXCOORD0;
};

float4 PSMain(PSInput input) : SV_TARGET
{
    return float4(input.Color, 1.0);
}
