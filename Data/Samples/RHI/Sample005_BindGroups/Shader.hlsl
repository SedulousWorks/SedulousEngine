// Sample005_BindGroups: Shader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: vertex VSMain
// entry: fragment PSMain

cbuffer GlobalUBO : register(b0, space0) { row_major float4x4 VP; };
cbuffer ObjectUBO : register(b0, space1) { row_major float4x4 Model; float4 ObjColor; };
struct VSInput { float3 Position : TEXCOORD0; float3 Normal : TEXCOORD1; };
struct PSInput { float4 Position : SV_POSITION; float3 Normal : NORMAL; float4 Color : COLOR; };
PSInput VSMain(VSInput i) {
    PSInput o;
    float4 wp = mul(float4(i.Position, 1.0), Model);
    o.Position = mul(wp, VP);
    o.Normal = mul(i.Normal, (float3x3)Model);
    o.Color = ObjColor;
    return o;
}
float4 PSMain(PSInput i) : SV_TARGET {
    float3 ld = normalize(float3(0.5, 1.0, -0.7));
    float ndotl = max(dot(normalize(i.Normal), ld), 0.0);
    return float4(i.Color.rgb * (0.2 + 0.8 * ndotl), 1.0);
}
