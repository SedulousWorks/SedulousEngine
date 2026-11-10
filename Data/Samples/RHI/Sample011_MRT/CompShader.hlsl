// Sample011_MRT: CompShader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: vertex VSMain
// entry: fragment PSMain

Texture2D gColorTex : register(t0, space0);
Texture2D gBrightTex : register(t1, space0);
SamplerState gSampler : register(s0, space0);
struct PSInput { float4 Position : SV_POSITION; float2 TexCoord : TEXCOORD0; };
PSInput VSMain(uint vid : SV_VertexID) { PSInput o;
    float2 uv = float2((vid << 1) & 2, vid & 2);
    o.Position = float4(uv * 2.0 - 1.0, 0, 1); o.TexCoord = float2(uv.x, 1.0 - uv.y); return o; }
float4 PSMain(PSInput i) : SV_TARGET {
    float2 uv = i.TexCoord;
    if (uv.x < 0.5) return gColorTex.Sample(gSampler, float2(uv.x*2, uv.y));
    else return gBrightTex.Sample(gSampler, float2((uv.x-0.5)*2, uv.y)); }
