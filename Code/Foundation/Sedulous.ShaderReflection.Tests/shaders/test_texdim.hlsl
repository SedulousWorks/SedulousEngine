// Test shader with various texture dimensions.
//
// Compile:
//   dxc -T ps_6_0 -E PSMain -Fo test_texdim_ps.dxil test_texdim.hlsl
//   dxc -T ps_6_0 -E PSMain -spirv -Fo test_texdim_ps.spv test_texdim.hlsl

Texture2D        Tex2D     : register(t0, space0);
TextureCube      TexCube   : register(t1, space0);
Texture2DArray   Tex2DArr  : register(t2, space0);
Texture3D        Tex3D     : register(t3, space0);
SamplerState     Samp      : register(s0, space0);

struct PSInput
{
    float4 Position : SV_POSITION;
    float3 TexCoord : TEXCOORD0;
};

float4 PSMain(PSInput input) : SV_TARGET
{
    float4 result = float4(0, 0, 0, 0);
    result += Tex2D.Sample(Samp, input.TexCoord.xy);
    result += TexCube.Sample(Samp, input.TexCoord);
    result += Tex2DArr.Sample(Samp, input.TexCoord);
    result += Tex3D.Sample(Samp, input.TexCoord);
    return result;
}
