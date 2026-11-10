// Sample015_Queries: Shader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: vertex VSMain
// entry: fragment PSMain

struct VSInput { float3 Position : TEXCOORD0; float4 Color : TEXCOORD1; };
struct PSInput { float4 Position : SV_POSITION; float4 Color : COLOR0; };
PSInput VSMain(VSInput i) { PSInput o; o.Position = float4(i.Position,1); o.Color = i.Color; return o; }
float4 PSMain(PSInput i) : SV_TARGET { return i.Color; }
