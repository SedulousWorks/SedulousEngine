// Text rendering vertex shader
// Receives vertex data from vertex buffer and projection from uniform buffer

struct VSInput
{
    float2 position : POSITION;
    float2 texCoord : TEXCOORD0;
    float4 color : COLOR0;
};

struct VSOutput
{
    float4 position : SV_Position;
    float2 texCoord : TEXCOORD0;
    float4 color : COLOR0;
};

// Uniform buffer with projection matrix (row_major to match CPU-side Matrix layout)
cbuffer Uniforms : register(b0)
{
    float4x4 projection;
};

VSOutput main(VSInput input)
{
    VSOutput output;
    output.position = mul(projection, float4(input.position, 0.0, 1.0));
    output.texCoord = input.texCoord;
    output.color = input.color;
    return output;
}
