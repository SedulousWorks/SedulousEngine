// Sample018_Bindless: Shader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: vertex VSMain
// entry: fragment PSMain

Texture2D gTextures[] : register(t0, space0);
SamplerState gSampler : register(s0, space1);

struct PushData
{
    uint TextureIndex;
    float OffsetX;
    float OffsetY;
    float Padding;
};

[[vk::push_constant]] ConstantBuffer<PushData> gPush : register(b0, space2);

struct PSInput
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
};

PSInput VSMain(uint vertexID : SV_VertexID)
{
    // Fullscreen-quad-style: 4 vertices for a unit quad
    float2 positions[4] = {
        float2(-0.4, 0.4),
        float2( 0.4, 0.4),
        float2(-0.4,-0.4),
        float2( 0.4,-0.4)
    };
    float2 uvs[4] = {
        float2(0, 0), float2(1, 0),
        float2(0, 1), float2(1, 1)
    };

    PSInput output;
    float2 pos = positions[vertexID];
    pos.x += gPush.OffsetX;
    pos.y += gPush.OffsetY;
    output.Position = float4(pos, 0.0, 1.0);
    output.TexCoord = uvs[vertexID];
    return output;
}

float4 PSMain(PSInput input) : SV_TARGET
{
    return gTextures[gPush.TextureIndex].Sample(gSampler, input.TexCoord);
}
