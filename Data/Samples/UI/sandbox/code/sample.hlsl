// The Code page's shader: a lit surface with a rim, in the engine's HLSL.

#pragma region Inputs
cbuffer Frame : register(b0)
{
    float4x4 ViewProjection;
    float3 LightDirection;
    float Time;
};

struct VertexIn
{
    float3 Position : POSITION;
    float3 Normal : NORMAL;
};

struct VertexOut
{
    float4 Position : SV_Position;
    float3 Normal : TEXCOORD0;
};
#pragma endregion

VertexOut VSMain(VertexIn input)
{
    VertexOut output;
    output.Position = mul(ViewProjection, float4(input.Position, 1.0));
    output.Normal = normalize(input.Normal);
    return output;
}

float4 PSMain(VertexOut input) : SV_Target
{
    const float lit = saturate(dot(input.Normal, -LightDirection));
    const float rim = pow(1.0 - saturate(input.Normal.z), 3.0);
    // The rim pulses with time: brightest facing away from the viewer, and fading to nothing where the surface faces it head on (a line long enough for soft wrap, Alt+Z).
    const float pulse = 0.5 + 0.5 * sin(Time * 2.0);
    return float4(float3(0.2, 0.45, 0.9) * lit + rim * pulse, 1.0);
}
