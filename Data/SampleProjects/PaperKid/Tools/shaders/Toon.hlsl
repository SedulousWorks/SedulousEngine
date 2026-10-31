// PaperKid's toon shading: the street as a printed comic, to go with the newsprint screens. A
// low-level shader after the Shader Gallery's Toon lesson, as Sky Hopper's is, but its own take:
// the light falls in hard steps, the dark side is the albedo in a warm paper shade, and an inked
// edge where a surface turns from the eye. The engine's vertex stage, lights, shadows and deferred targets.
// Every PBR material of the game is on it (Tools/toon.py), its colour and map carried over.

// variants(vertex): SKINNED INSTANCED
// variants(fragment): ALPHA_TEST GBUFFER DITHER
// preserve-interface (the pixel stage keeps VSOutput's fade input when DITHER is off)

#define FORWARD_VS_ENTRY VSMain
#include "forward_vs.hlsli"

#include "lighting.hlsli"
#include "forward_ps.hlsli"

properties
{
    Color   BaseColor        = (1, 1, 1, 1);
    Color   PaperShade       = (0.74, 0.66, 0.58, 1); // the dark side's tint: warm, as ink on newsprint
    Color   InkColor         = (0.16, 0.13, 0.12, 1); // the edge
    float   Bands            = 2    [1, 6];           // how many steps the light falls into
    float   BandSoftness     = 0.03 [0, 0.5];         // 0 cuts each step hard; 0.5 is a smooth ramp
    float   EdgeWidth        = 0.28 [0, 1];           // how far in from the silhouette the edge reaches
    float   EdgeStrength     = 0.8  [0, 1];
    float   AlphaCutoff      = 0.5  [0, 1];           // the ALPHA_TEST threshold
    Texture AlbedoMap;
    Sampler MainSampler;
}

// The light reaching a surface in `Bands` steps, each edge a smoothstep `BandSoftness` wide.
float InkBands(float value, float bands, float softness) {
    float b = max(bands, 1.0);
    float x = saturate(value) * b;
    float s = max(softness, 0.001);
    return saturate((floor(x) + smoothstep(0.5 - s, 0.5 + s, frac(x))) / b);
}

// One light's share of how lit a surface is, 0 to 1: banded facing, its shadow a hard step of its
// own (banded with the facing, the shadow map's filtered edge would become a band).
float InkLight(GpuLight light, float3 worldPos, float3 N, float shadow, out float3 radiance) {
    float atten;
    float3 L = LightDirection(light, worldPos, atten);
    // Divided by pi as the engine's diffuse is, so a light and the exposure tuned for PBR light
    // the toon to the same brightness.
    radiance = light.color * light.intensity * saturate(atten) * (1.0 / 3.14159265);
    return InkBands(dot(N, L), Bands, BandSoftness) * smoothstep(0.4, 0.6, shadow);
}

#ifdef GBUFFER
GBufferOutput PSMain(VSOutput input) {
#else
float4 PSMain(VSOutput input) : SV_Target0 {
#endif
#ifdef DITHER
    ScreenDoorFade(input.clip.xy, input.fade);
#endif
    float4 albedoTex = AlbedoMap.Sample(MainSampler, input.uv);
    float3 albedo = input.color.rgb * BaseColor.rgb * albedoTex.rgb;
    float  alpha  = saturate(input.color.a * BaseColor.a * albedoTex.a);
#ifdef ALPHA_TEST
    if (alpha < AlphaCutoff) { discard; }
#endif
    float3 N = normalize(input.normalWS);
    float3 V = normalize(CameraPos - input.worldPos);
    float  viewDepth = -mul(float4(input.worldPos, 1.0), View).z;
    float3 shade = PaperShade.rgb * albedo;

    // The scene's fill, in the paper shade: what the sun does not reach is printed, not black.
    float3 color = Ambient * shade;
    LightList lights = LightsAt(input.clip.xy, viewDepth);
    for (uint i = 0; i < lights.count; ++i) {
        GpuLight L = LightAt(lights, i);
        float3 radiance;
        float lit = InkLight(L, input.worldPos, N, ShadowOf(L, input.worldPos, N, viewDepth), radiance);
        color += lerp(shade, albedo, lit) * radiance;
    }

    // Ink: the edge where the surface turns away.
    float facing = saturate(dot(N, V));
    float edge = 1.0 - smoothstep(EdgeWidth * 0.5, EdgeWidth, facing);
    color = lerp(color, InkColor.rgb, edge * EdgeStrength);

#ifdef GBUFFER
    GBufferOutput o;
    o.color    = float4(color, alpha);
    o.normal   = OctEncode(normalize(mul(float4(N, 0.0), View).xyz));
    o.velocity = MotionVector(input.curClip, input.prevClip);
    o.material = float2(1.0, 0.0);                          // fully rough, not metal: SSR skips it
    o.albedo   = float4(albedo, 1.0);
    return o;
#else
    return float4(color, alpha);
#endif
}
