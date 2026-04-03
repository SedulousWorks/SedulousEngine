// Test shader with various resource binding types.
// Vertex shader with: uniform buffer, sampled texture, sampler, storage buffer.
//
// Compile:
//   dxc -T vs_6_0 -E VSMain -Fo test_bindings_vs.dxil test_bindings.hlsl
//   dxc -T vs_6_0 -E VSMain -spirv -Fo test_bindings_vs.spv test_bindings.hlsl
//   dxc -T ps_6_0 -E PSMain -Fo test_bindings_ps.dxil test_bindings.hlsl
//   dxc -T ps_6_0 -E PSMain -spirv -Fo test_bindings_ps.spv test_bindings.hlsl

struct VSInput
{
    float3 Position : TEXCOORD0;
    float2 TexCoord : TEXCOORD1;
    uint4  BoneIds  : TEXCOORD2;
};

struct PSInput
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
};

cbuffer SceneConstants : register(b0, space0)
{
    float4x4 ViewProjection;
    float4   CameraPos;
};

cbuffer ModelConstants : register(b1, space0)
{
    float4x4 World;
};

Texture2D    DiffuseMap : register(t0, space1);
SamplerState LinearSampler : register(s0, space1);

StructuredBuffer<float4> BoneBuffer : register(t1, space1);

PSInput VSMain(VSInput input)
{
    PSInput output;
    // Use BoneBuffer to prevent it from being optimized out
    float4 boneOffset = BoneBuffer[input.BoneIds.x];
    float4 worldPos = mul(World, float4(input.Position + boneOffset.xyz, 1.0));
    output.Position = mul(ViewProjection, worldPos);
    output.TexCoord = input.TexCoord;
    return output;
}

float4 PSMain(PSInput input) : SV_TARGET
{
    return DiffuseMap.Sample(LinearSampler, input.TexCoord);
}
