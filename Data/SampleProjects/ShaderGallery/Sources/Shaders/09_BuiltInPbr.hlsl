// Lesson 9: Built-in PBR. The engine's own material, written as a surface.
//
// Builds on lessons 2 and 5. Nothing new in the language: this is what the engine's PBR Material
// does, as a surface shader, so it is the reference to start from when a shader should look like
// the rest of the scene with one thing changed. The engine shades it physically: albedo is the
// colour under white light, metallic picks metal or not, roughness spreads the reflection,
// occlusion darkens creases, emission glows. Unbound, the albedo map reads as white and the
// normal map as flat, so each map is optional.
// surface: lit

properties
{
    Color   BaseColour     = (0.95, 0.64, 0.54, 1);   // copper
    float   Metallic       = 1    [0, 1];
    float   Roughness      = 0.3  [0, 1];
    float   NormalStrength = 0.35 [0, 2];
    float   Tiling         = 1    [0.25, 8];
    Color   Emission       = (0, 0, 0, 1);
    float   EmissionPower  = 0    [0, 20];
    Texture AlbedoMap;
    Texture NormalMap;
    Sampler MainSampler;
}

void Surface(SurfaceInput input, inout SurfaceOutput surface)
{
    float2 uv = input.uv * Tiling;
    float4 albedo = AlbedoMap.Sample(MainSampler, uv);
    surface.albedo = albedo.rgb * BaseColour.rgb * input.color.rgb;
    surface.alpha = albedo.a * BaseColour.a;
    surface.metallic = Metallic;
    surface.roughness = Roughness;
    float3 n = NormalMap.Sample(MainSampler, uv).xyz * 2.0 - 1.0;
    surface.normal = normalize(float3(n.xy * NormalStrength, n.z));
    surface.emissive = Emission.rgb * EmissionPower;
}
