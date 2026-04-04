// Minimal unlit fragment shader
// Outputs vertex color directly

struct FragmentInput
{
    float4 Position : SV_Position;
    float4 Color : COLOR;
};

float4 main(FragmentInput input) : SV_Target
{
    return input.Color;
}
