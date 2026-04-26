// Unlit Fragment Shader
// Simple color output without lighting calculations.
// Material layout matches Materials.CreateUnlit() uniform buffer.

#pragma pack_matrix(row_major)

// Set 2: Material data - matches Materials.CreateUnlit() layout
// Layout (std140): BaseColor(0), EmissiveColor(16), AlphaCutoff(32)
cbuffer MaterialUniforms : register(b0, space2)
{
    float4 BaseColor;       // offset 0
    float4 EmissiveColor;   // offset 16
    float AlphaCutoff;      // offset 32
    float3 _Padding;        // pad to 48
};

// Material textures (set 2)
Texture2D AlbedoMap : register(t0, space2);

// Material sampler (set 2)
SamplerState MainSampler : register(s0, space2);

struct FragmentInput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
#ifdef VERTEX_COLORS
    float4 Color : TEXCOORD1;
#endif
};

float4 main(FragmentInput input) : SV_Target
{
    // Sample albedo texture
    float4 albedo = AlbedoMap.Sample(MainSampler, input.TexCoord) * BaseColor;

#ifdef VERTEX_COLORS
    albedo *= input.Color;
#endif

#ifdef ALPHA_TEST
    if (albedo.a < AlphaCutoff)
        discard;
#endif

    // Add emissive
    float3 color = albedo.rgb + EmissiveColor.rgb;

    return float4(color, albedo.a);
}
