// Lesson 10: Toon. A low-level shader: lighting of its own.
//
// The first low-level shader. A surface shader says what a surface is and the engine lights it; a
// low-level shader is the whole drawing program, both stages, so it can light the surface however
// it likes. This one lights it in hard bands, with a colour of its own for the dark side and a
// bright rim, in place of the engine's physically based light. What it keeps of the engine's:
//   - the vertex stage, which the engine's library writes for it (below, under its own name);
//   - the frame's lights, shadows and fog (the lighting library), which it walks itself;
//   - the targets the effects after it read, under GBUFFER (colour, normal, motion and so on).
// The `variants` lines say which versions the engine may ask for: skinned or instanced meshes,
// cut-out materials (ALPHA_TEST), the deferred targets (GBUFFER), the distance fade (DITHER).

// variants(vertex): SKINNED INSTANCED
// variants(fragment): ALPHA_TEST GBUFFER DITHER
// preserve-interface (the pixel stage keeps VSOutput's fade input when DITHER is off)

// ==== The vertex stage: the engine's, named VSMain ====
#define FORWARD_VS_ENTRY VSMain
#include "forward_vs.hlsli"

// ==== The frame's lights and shadows, and the pixel stage's input and outputs ====
#include "lighting.hlsli"
#include "forward_ps.hlsli"

// ==== The material: a properties block, as a surface shader's ====
properties
{
    Color   BaseColor    = (1, 1, 1, 1);
    Color   ShadowColor  = (0.3, 0.1, 0.1, 1); // the colour of the unlit side
    Color   RimColor     = (1, 0.95, 0.85, 1);
    float   Bands        = 3   [1, 8];          // how many steps the light falls into
    float   RimPower     = 3   [0.5, 16];       // how tight the rim is
    float   RimIntensity = 0.6 [0, 4];
    float   AlphaCutoff  = 0.5 [0, 1];          // the ALPHA_TEST threshold
    Texture AlbedoMap;
    Sampler MainSampler;
}

// The light reaching a surface, cut into `Bands` hard steps (0 = the shadow side, 1 = fully lit).
float Quantize(float value, float bands) {
    float b = max(bands, 1.0);
    return saturate(floor(value * b + 0.5) / b);
}

// One light: the banded diffuse between the shadow colour and the albedo. Where the light comes
// from and how far it reaches are the engine's (LightDirection); only the response is the toon's.
// The shadow is its own soft-edged step, not banded with the facing: banded together, the shadow
// map's filtered edge would become a band of its own.
float3 ToonLight(GpuLight light, float3 worldPos, float3 N, float3 albedo, float shadow) {
    float atten;
    float3 L = LightDirection(light, worldPos, atten);
    float lit = Quantize(saturate(dot(N, L)), Bands) * smoothstep(0.4, 0.6, shadow);
    float3 tone = lerp(ShadowColor.rgb * albedo, albedo, lit);
    return tone * light.color * light.intensity * saturate(atten);
}

// ==== The pixel stage ====
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

    // Ambient: the scene's flat fill, in the shadow colour.
    float3 color = Ambient * ShadowColor.rgb * albedo;

    // Every light that reaches this pixel, and its shadow here.
    LightList lights = LightsAt(input.clip.xy, viewDepth);
    for (uint i = 0; i < lights.count; ++i) {
        GpuLight L = LightAt(lights, i);
        color += ToonLight(L, input.worldPos, N, albedo, ShadowOf(L, input.worldPos, N, viewDepth));
    }

    // Rim light: a bright edge where the surface turns away from the eye.
    float rim = pow(1.0 - saturate(dot(N, V)), max(RimPower, 0.01));
    color += RimColor.rgb * rim * RimIntensity;

#ifdef GBUFFER
    GBufferOutput o;
    o.color    = float4(color, alpha);
    o.normal   = OctEncode(normalize(mul(float4(N, 0.0), View).xyz));
    o.velocity = MotionVector(input.curClip, input.prevClip);   // TAA reprojects with this
    o.material = float2(1.0, 0.0);                          // fully rough, not metal: SSR skips it
    o.albedo   = float4(albedo, 1.0);                       // SSGI tints its bounce by it
    return o;
#else
    return float4(color, alpha);
#endif
}
