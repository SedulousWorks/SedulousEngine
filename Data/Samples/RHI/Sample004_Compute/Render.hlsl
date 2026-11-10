// Sample004_Compute: Render, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: vertex VSMain
// entry: fragment PSMain

cbuffer ViewProj : register(b0, space0) { row_major float4x4 VP; };
struct VSInput { float3 Position : TEXCOORD0; float3 Color : TEXCOORD1; };
struct PSInput { float4 Position : SV_POSITION; float3 Color : COLOR0;
                 [[vk::builtin("PointSize")]] float PointSize : PSIZE; };
PSInput VSMain(VSInput i) { PSInput o; o.Position = mul(float4(i.Position,1), VP); o.Color = i.Color; o.PointSize = 1.0; return o; }
float4 PSMain(PSInput i) : SV_TARGET { return float4(i.Color, 1.0); }
