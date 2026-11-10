// Sample027_3DTexture: Shader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: vertex VSMain
// entry: fragment PSMain

Texture3D<float4> gVolume : register(t0, space0);
Texture1D<float4> gLUT    : register(t1, space0);
SamplerState gSampler     : register(s0, space0);

struct PushConstants
{
    float SliceZ;
    float Time;
    float2 _pad;
};

[[vk::push_constant]] ConstantBuffer<PushConstants> pc : register(b0, space1);

struct PSInput
{
    float4 Position : SV_POSITION;
    float2 UV       : TEXCOORD0;
};

PSInput VSMain(uint vertexID : SV_VertexID)
{
    PSInput output;
    float2 uv = float2((vertexID << 1) & 2, vertexID & 2);
    output.Position = float4(uv * 2.0 - 1.0, 0.5, 1.0);
    output.UV = uv;
    return output;
}

float4 PSMain(PSInput input) : SV_TARGET
{
    // Sample 3D volume at current slice
    float3 uvw = float3(input.UV, pc.SliceZ);
    float density = gVolume.Sample(gSampler, uvw).r;

    // Map density through 1D LUT
    float4 color = gLUT.Sample(gSampler, density);
    return color;
}
