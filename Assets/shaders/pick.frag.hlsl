// Entity pick fragment shader
// Encodes entity index as RGBA8 color for GPU readback.
// Index 0 = background (no entity).

struct PSInput
{
    float4 Position : SV_Position;
    nointerpolation uint EntityIndex : TEXCOORD0;
};

float4 main(PSInput input) : SV_Target
{
    // Encode 32-bit entity index into 4 x 8-bit channels.
    // +1 so that entity index 0 maps to (1,0,0,0) and background is (0,0,0,0).
    uint id = input.EntityIndex + 1;
    float r = float((id >>  0) & 0xFF) / 255.0;
    float g = float((id >>  8) & 0xFF) / 255.0;
    float b = float((id >> 16) & 0xFF) / 255.0;
    float a = float((id >> 24) & 0xFF) / 255.0;
    return float4(r, g, b, a);
}
