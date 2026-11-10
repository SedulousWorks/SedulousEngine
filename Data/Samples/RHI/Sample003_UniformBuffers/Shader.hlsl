// Sample003_UniformBuffers: Shader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: vertex VSMain
// entry: fragment PSMain

cbuffer UBO : register(b0, space0) { row_major float4x4 MVP; };
struct PushData { float4 Tint; };
[[vk::push_constant]] ConstantBuffer<PushData> gPush : register(b0, space1);
struct VSInput { float3 Position : TEXCOORD0; float3 Color : TEXCOORD1; };
struct PSInput { float4 Position : SV_POSITION; float3 Color : COLOR0; };
PSInput VSMain(VSInput input) {
    PSInput o; o.Position = mul(float4(input.Position, 1.0), MVP); o.Color = input.Color; return o;
}
float4 PSMain(PSInput input) : SV_TARGET { return float4(input.Color * gPush.Tint.rgb, 1.0); }
