// Fullscreen triangle vertex shader via SV_VertexID.
// Shared by tonemap, bloom, blit, and any other full-screen post-process passes.

struct VertexOutput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
};

VertexOutput main(uint vertexID : SV_VertexID)
{
    VertexOutput output;

    float2 uv = float2((vertexID << 1) & 2, vertexID & 2);
    output.Position = float4(uv * 2.0 - 1.0, 0.0, 1.0);
    output.TexCoord = float2(uv.x, 1.0 - uv.y);

    return output;
}
