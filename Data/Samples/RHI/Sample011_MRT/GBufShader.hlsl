// Sample011_MRT: GBufShader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: vertex VSMain
// entry: fragment PSMain

struct VSInput { float3 Position : TEXCOORD0; float4 Color : TEXCOORD1; };
struct PSInput { float4 Position : SV_POSITION; float4 Color : COLOR0; };
struct PSOutput { float4 Color : SV_TARGET0; float4 Brightness : SV_TARGET1; };
PSInput VSMain(VSInput i) { PSInput o; o.Position = float4(i.Position,1); o.Color = i.Color; return o; }
PSOutput PSMain(PSInput i) { PSOutput o; o.Color = i.Color;
    float lum = dot(i.Color.rgb, float3(0.299,0.587,0.114));
    o.Brightness = float4(lum,lum,lum,1); return o; }
