// Sprite fragment shader — samples texture and multiplies by tint.

Texture2D    SpriteTexture : register(t0, space2);
SamplerState SpriteSampler : register(s0, space2);

struct FragmentInput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
    float4 Color    : COLOR0;
};

float4 main(FragmentInput input) : SV_Target
{
    float4 sample = SpriteTexture.Sample(SpriteSampler, input.TexCoord);
    return sample * input.Color;
}
