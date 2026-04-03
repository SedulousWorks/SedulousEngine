// Triangle sample shader — position + color passthrough.
// Compile with DXC:
//   Vertex DXIL:  dxc -T vs_6_0 -E VSMain -Fo triangle_vs.dxil triangle.hlsl
//   Pixel  DXIL:  dxc -T ps_6_0 -E PSMain -Fo triangle_ps.dxil triangle.hlsl
//   Vertex SPIRV: dxc -T vs_6_0 -E VSMain -spirv -Fo triangle_vs.spv triangle.hlsl
//   Pixel  SPIRV: dxc -T ps_6_0 -E PSMain -spirv -Fo triangle_ps.spv triangle.hlsl

struct VSInput
{
    float3 Position : TEXCOORD0;
    float3 Color    : TEXCOORD1;
};

struct PSInput
{
    float4 Position : SV_POSITION;
    float3 Color    : TEXCOORD0;
};

PSInput VSMain(VSInput input)
{
    PSInput output;
    output.Position = float4(input.Position, 1.0);
    output.Color = input.Color;
    return output;
}

float4 PSMain(PSInput input) : SV_TARGET
{
    return float4(input.Color, 1.0);
}
