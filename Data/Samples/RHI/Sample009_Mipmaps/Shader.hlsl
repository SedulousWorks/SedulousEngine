// Sample009_Mipmaps: Shader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: vertex VSMain
// entry: fragment PSMain

Texture2D gTexture : register(t0, space0);
SamplerState gSampler : register(s0, space0);
cbuffer UBO : register(b0, space1) { row_major float4x4 MVP; };
struct VSInput { float3 Position : TEXCOORD0; float2 TexCoord : TEXCOORD1; };
struct PSInput { float4 Position : SV_POSITION; float2 TexCoord : TEXCOORD0; };
PSInput VSMain(VSInput i) { PSInput o; o.Position = mul(float4(i.Position,1), MVP); o.TexCoord = i.TexCoord; return o; }
float4 PSMain(PSInput i) : SV_TARGET { return gTexture.Sample(gSampler, i.TexCoord); }
