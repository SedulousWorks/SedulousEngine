// Lesson 11: Custom Lighting. Walking the lights yourself.
//
// Builds on lesson 10, which banded the engine's light; this one writes a lighting model from the
// start, the kind older games used: half-Lambert diffuse (the dark side wraps round, never black)
// and a Blinn-Phong highlight. The lighting library gives the parts:
//   LightsAt(pixel, depth)   the lights that reach this pixel (clustered when the scene is);
//   LightAt(list, i)         one of them: its type, colour, intensity, position or direction;
//   LightDirection(...)      the direction to it and how much of it arrives (range, spot cone);
//   ShadowOf(light, ...)     how much of it the shadow maps let through, 1 unshadowed;
//   AmbientLight(...)        the sky and the reflection probes' light, as the engine's PBR has it.
// The rest of the file is lesson 10's frame: the same variants, vertex stage and outputs.

// variants(vertex): SKINNED INSTANCED
// variants(fragment): ALPHA_TEST GBUFFER DITHER
// preserve-interface (the pixel stage keeps VSOutput's fade input when DITHER is off)

#define FORWARD_VS_ENTRY VSMain
#include "forward_vs.hlsli"
#include "lighting.hlsli"
#include "forward_ps.hlsli"

properties
{
    Color   BaseColor     = (0.35, 0.55, 0.9, 1);
    Color   SpecularColor = (1, 1, 1, 1);
    float   Wrap          = 0.5  [0, 1];     // 0 is plain Lambert; 1 lights the back half-way
    float   Shininess     = 48   [2, 256];   // how small and sharp the highlight is
    float   Specular      = 0.6  [0, 2];
    float   AmbientAmount = 1    [0, 2];
    float   AlphaCutoff   = 0.5  [0, 1];
    Texture AlbedoMap;
    Sampler MainSampler;
}

// One light: wrapped diffuse plus a Blinn-Phong highlight, dimmed by its shadow.
float3 ShadeLight(GpuLight light, float3 worldPos, float3 N, float3 V, float3 albedo, float shadow) {
    float atten;
    float3 L = LightDirection(light, worldPos, atten);
    // Half-Lambert: dot(N, L) from -1..1 squeezed toward 0..1, so the light wraps past the edge.
    float diffuse = saturate((dot(N, L) + Wrap) / (1.0 + Wrap));
    // Blinn-Phong: the half vector between the light and the eye; near the normal, a highlight.
    float3 H = normalize(L + V);
    float highlight = pow(saturate(dot(N, H)), Shininess) * Specular * step(0.0, dot(N, L));
    float3 lit = albedo * diffuse + SpecularColor.rgb * highlight;
    return lit * light.color * light.intensity * saturate(atten) * shadow;
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

    // The sky's light and the probes', as for a rough non-metal (F0 0.04 is most non-metals).
    float3 color = AmbientLight(input.worldPos, N, V, albedo, 0.6, 0.0, float3(0.04, 0.04, 0.04), 1.0)
                 * AmbientAmount;

    LightList lights = LightsAt(input.clip.xy, viewDepth);
    for (uint i = 0; i < lights.count; ++i) {
        GpuLight L = LightAt(lights, i);
        color += ShadeLight(L, input.worldPos, N, V, albedo, ShadowOf(L, input.worldPos, N, viewDepth));
    }

#ifdef GBUFFER
    GBufferOutput o;
    o.color    = float4(color, alpha);
    o.normal   = OctEncode(normalize(mul(float4(N, 0.0), View).xyz));
    o.velocity = MotionVector(input.curClip, input.prevClip);
    o.material = float2(0.6, 0.0);                          // rough-ish, not metal
    o.albedo   = float4(albedo, 1.0);
    return o;
#else
    return float4(color, alpha);
#endif
}
