// Particle fragment shader — samples texture and multiplies by vertex color.

Texture2D    ParticleTexture : register(t0, space2);
SamplerState ParticleSampler : register(s0, space2);

struct FragmentInput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
    float4 Color    : COLOR0;
};

float4 main(FragmentInput input) : SV_Target
{
    float4 texSample = ParticleTexture.Sample(ParticleSampler, input.TexCoord);
    float4 result = texSample * input.Color;

    // Discard fully transparent fragments to avoid depth writes.
    clip(result.a - 0.001);

    return result;
}
