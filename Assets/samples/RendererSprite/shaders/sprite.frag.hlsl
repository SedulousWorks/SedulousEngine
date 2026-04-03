// Sprite Fragment Shader
// Simple textured sprite with color tint

struct PSInput
{
    float4 position : SV_Position;
    float2 uv : TEXCOORD0;
    float4 color : COLOR;
};

// For untextured sprites, just use the vertex color
float4 main(PSInput input) : SV_Target
{
    // Simple colored sprite (no texture for now)
    return input.color;
}
