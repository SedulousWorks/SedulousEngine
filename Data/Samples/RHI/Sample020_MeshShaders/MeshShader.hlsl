// Sample020_MeshShaders: MeshShader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: mesh MSMain
// model: 6_5

struct PushConstants
{
    float Time;
    float AspectRatio;
    float Pad0, Pad1;
};

[[vk::push_constant]] ConstantBuffer<PushConstants> pc : register(b0, space0);

struct MeshOutput
{
    float4 Position : SV_POSITION;
    float3 Color    : TEXCOORD0;
};

[outputtopology("triangle")]
[numthreads(1, 1, 1)]
void MSMain(out vertices MeshOutput verts[3], out indices uint3 tris[1])
{
    SetMeshOutputCounts(3, 1);

    float angle = pc.Time * 0.5;
    float c = cos(angle);
    float s = sin(angle);

    float2 positions[3] = {
        float2( 0.0,  0.5),
        float2(-0.5, -0.5),
        float2( 0.5, -0.5)
    };

    float3 colors[3] = {
        float3(1.0, 0.0, 0.0),
        float3(0.0, 1.0, 0.0),
        float3(0.0, 0.0, 1.0)
    };

    for (uint i = 0; i < 3; i++)
    {
        float2 p = positions[i];
        float2 rotated = float2(p.x * c - p.y * s, p.x * s + p.y * c);
        rotated.x /= pc.AspectRatio;

        verts[i].Position = float4(rotated, 0.0, 1.0);
        verts[i].Color = colors[i];
    }

    tris[0] = uint3(0, 1, 2);
}
