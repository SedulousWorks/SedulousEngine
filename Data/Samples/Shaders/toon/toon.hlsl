// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The toon sample's shader (Code/Samples/Samples.CustomShader), both stages in one file: VSMain and PSMain,
// each registered by name. Cel shading in hard bands, a shadow colour and a rim light, in place of
// the engine's PBR. A LOW-LEVEL custom shader forks the whole lighting and keeps the frame's
// contract:
//   - the vertex stage: the mesh vertex in, VSOutput out, the SKINNED / INSTANCED variants.
//     The engine's forward vertex library is exactly that, so VSMain is it, under its own name.
//   - the pixel stage: the frame's lights, shadow maps and clusters (sets 0 and 3), which the
//     engine's lighting library declares, its material parameters in a properties block (the
//     engine generates set 2 from it), and under GBUFFER the five targets the post stack reads
//     (colour, view normal, motion vector, roughness/metallic, albedo).
// Ported from the previous engine's RenderMaterialsCustom sample.

// No wind sway: wind.hlsli reads the PBR material's layout, which a toon material does not have.
// variants(vertex): SKINNED INSTANCED
// variants(fragment): ALPHA_TEST GBUFFER DITHER
// preserve-interface (the pixel stage keeps VSOutput's fade input when DITHER is off)

// ==== The vertex stage ====
#define FORWARD_VS_ENTRY VSMain
#include "forward_vs.hlsli"

// ==== The rest of the frame (sets 0 and 3): the engine's lighting library ====
#include "lighting.hlsli"
#include "forward_ps.hlsli"

// ==== The toon material (set 2): declared once, here; the engine generates the declarations ====
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

// ==== Toon shading ====

// The light reaching a surface, cut into `Bands` hard steps (0 = the shadow side, 1 = fully lit).
float Quantize(float value, float bands) {
    float b = max(bands, 1.0);
    return saturate(floor(value * b + 0.5) / b);
}

// One light's toon contribution: the banded diffuse between the shadow colour and the albedo. The
// light reaches as far as the engine's lights do (LightDirection); only the response is stylised.
// Only the facing is banded; the shadow is one edge on its own. Banded together, the shadow map's
// filtered edge became a band of its own (a pale ring around every shadow) and the core's edge
// traced the shadow map's texels. The edge is a narrow smoothstep rather than a step, so it does
// not alias; a width from fwidth(shadow) would need uniform control flow, which this per-pixel
// light loop is not (WGSL refuses the derivative).
float3 ToonLight(GpuLight light, float3 worldPos, float3 N, float3 albedo, float shadow) {
    float atten;
    float3 L = LightDirection(light, worldPos, atten);
    float lit = Quantize(saturate(dot(N, L)), Bands) * smoothstep(0.4, 0.6, shadow);
    float3 tone = lerp(ShadowColor.rgb * albedo, albedo, lit);
    return tone * light.color * light.intensity * saturate(atten);
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

    // Ambient: the scene's flat fill, in the shadow colour.
    float3 color = Ambient * ShadowColor.rgb * albedo;

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
