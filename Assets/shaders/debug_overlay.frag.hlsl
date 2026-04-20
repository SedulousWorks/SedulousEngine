// Debug overlay fragment shader - samples the R8 font atlas and multiplies by
// the vertex color. Rectangles sample a solid-white region of the atlas so the
// same shader works for text and rect draws.

Texture2D FontAtlas : register(t0, space2);
SamplerState FontSampler : register(s0, space2);

struct FragmentInput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR0;
};

float4 main(FragmentInput input) : SV_Target
{
    float alpha = FontAtlas.Sample(FontSampler, input.TexCoord).r;
    return float4(input.Color.rgb, input.Color.a * alpha);
}
