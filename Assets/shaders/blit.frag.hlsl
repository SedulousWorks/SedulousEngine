// Fullscreen Blit Fragment Shader
// Simple copy from source texture to output

Texture2D SourceTexture : register(t0);
SamplerState LinearSampler : register(s0);

struct FragmentInput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
};

float4 main(FragmentInput input) : SV_Target
{
    return SourceTexture.Sample(LinearSampler, input.TexCoord);
}
