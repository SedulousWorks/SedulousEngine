// Fullscreen Blit Vertex Shader
// Uses SV_VertexID to generate a fullscreen triangle (no vertex buffer needed)

struct VertexOutput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
};

VertexOutput main(uint vertexID : SV_VertexID)
{
    VertexOutput output;

    // Generate fullscreen triangle from vertex ID
    // Covers [-1,-1] to [3,-1] to [-1,3] in clip space
    float2 uv = float2((vertexID << 1) & 2, vertexID & 2);
    output.Position = float4(uv * 2.0 - 1.0, 0.0, 1.0);
    output.TexCoord = float2(uv.x, 1.0 - uv.y);

    return output;
}
