// Sample023_CubeMap: SkyboxShader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: vertex VSMain
// entry: fragment PSMain

TextureCube<float4> gCubeMap : register(t0, space0);
SamplerState gSampler : register(s0, space0);

struct PushConstants
{
    float Time;
    float AspectRatio;
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
    // Fullscreen triangle
    float2 uv = float2((vertexID << 1) & 2, vertexID & 2);
    output.Position = float4(uv * 2.0 - 1.0, 0.5, 1.0);
    output.UV = uv;
    return output;
}

float4 PSMain(PSInput input) : SV_TARGET
{
    // Convert UV to ray direction
    float2 ndc = input.UV * 2.0 - 1.0;
    ndc.x *= pc.AspectRatio;
    ndc.y = -ndc.y;

    // Simple rotation around Y
    float c = cos(pc.Time * 0.3);
    float s = sin(pc.Time * 0.3);

    float3 dir = normalize(float3(ndc.x, ndc.y, 1.0));
    float3 rotDir = float3(dir.x * c + dir.z * s, dir.y, -dir.x * s + dir.z * c);

    return gCubeMap.Sample(gSampler, rotDir);
}
