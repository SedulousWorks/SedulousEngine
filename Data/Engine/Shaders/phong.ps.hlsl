// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The builtin Phong material (Raptor's phong-material spec): what a model authored with Phong or Lambert
// is drawn with, so it looks as it was made. Each light that reaches the pixel (its cluster's, or
// every light) is shaded Blinn-Phong, in the units the PBR path uses so the two sit side by side:
// the diffuse (BaseColor x AlbedoMap x the vertex colour) by N.L over pi, and the specular
// (SpecularColor x SpecularMap) as a highlight normalised by its exponent, so a tight one is not
// brighter overall than a broad one. The ambient is the scene's diffuse ambient alone (the sky's
// irradiance where there is one, plus its flat ambient): Phong has no reflection of its
// surroundings. The emission is added on top.
// variants: ALPHA_TEST GBUFFER DITHER
// preserve-interface
// (Keeps every input of forward_vs.hlsli's VSOutput in the interface, read or not: a variant that
// does not read one (the fade without DITHER) would otherwise leave a vertex output unmatched.)
#include "lighting.hlsli"
#include "forward_ps.hlsli"
cbuffer Material : register(b0, space2) {    // as CreatePhong lays it out (MaterialPresets.bf)
    float4 BaseColor;          // the diffuse colour (PBR's and Unlit's name, so a switch keeps it)
    float4 SpecularColor;      // black: no highlight (a Lambert material)
    float4 EmissiveColor;      // rgb x EmissiveMap = emitted radiance, its intensity in w
    float  Shininess;          // the highlight's exponent (Phong's specular exponent)
    float  NormalScale;        // scales the tangent-space XY perturbation
    float  AlphaCutoff;        // ALPHA_TEST threshold
};
// Unset maps bind a neutral default (white for the albedo, specular and emissive, a flat normal), so
// a material's colours alone are what it shows.
Texture2D    AlbedoMap   : register(t0, space2);   // the diffuse map
Texture2D    SpecularMap : register(t1, space2);
Texture2D    NormalMap   : register(t2, space2);
Texture2D    EmissiveMap : register(t3, space2);
SamplerState MainSampler : register(s0, space2);
struct PSInput {
    float4 clip      : SV_Position;
    float3 normalWS  : TEXCOORD0;
    float4 color     : TEXCOORD1;
    float2 uv        : TEXCOORD2;
    float4 tangentWS : TEXCOORD3;   // xyz world tangent, w handedness
    float3 worldPos  : TEXCOORD4;
    float4 curClip   : TEXCOORD5;   // motion vectors (unjittered current/previous clip pos)
    float4 prevClip  : TEXCOORD6;
    nointerpolation float fade : TEXCOORD7;   // screen-door fade, 0 = solid (read under DITHER)
};

// One light's Blinn-Phong: diffuse by N.L over pi as the PBR path's Lambert is, and a normalised
// highlight ((n + 8) / (8 pi) keeps its energy as the exponent n tightens it).
float3 PhongLight(GpuLight light, float3 worldPos, float3 N, float3 V, float3 diffuse, float3 specular, float exponent) {
    float atten;
    float3 L = LightDirection(light, worldPos, atten);
    float NdotL = saturate(dot(N, L));
    if (NdotL <= 0.0) { return float3(0.0, 0.0, 0.0); }
    float3 H = normalize(V + L);
    float  NdotH = saturate(dot(N, H));
    float  highlight = (exponent + 8.0) / (8.0 * PI) * pow(NdotH, exponent);
    return (diffuse / PI + specular * highlight) * (light.color * light.intensity) * NdotL * atten;
}

#ifdef GBUFFER
GBufferOutput main(PSInput input) {
#else
float4 main(PSInput input) : SV_Target0 {
#endif
#ifdef DITHER
    ScreenDoorFade(input.clip.xy, input.fade);
#endif
    // Tangent-space normal mapping, as forward does: the map sampled in uniform control flow (WGSL
    // refuses an implicit-derivative sample in a per-pixel branch), its result used only where the
    // tangent is sound.
    float3 N = normalize(input.normalWS);
    {
        float3 nTex = NormalMap.Sample(MainSampler, input.uv).xyz * 2.0 - 1.0;
        float3 T = input.tangentWS.xyz - N * dot(input.tangentWS.xyz, N);
        float  tLen = length(T);
        if (tLen > 1e-4) {
            T /= tLen;
            float3 B = cross(N, T) * input.tangentWS.w;
            nTex.xy *= NormalScale;
            N = normalize(nTex.x * T + nTex.y * B + nTex.z * N);
        }
    }
    float3 V = ViewDirToCamera(input.worldPos);

    float4 diffuseTex = AlbedoMap.Sample(MainSampler, input.uv);
    float3 diffuse    = input.color.rgb * BaseColor.rgb * diffuseTex.rgb;
    float  alpha      = saturate(input.color.a * BaseColor.a * diffuseTex.a);
#ifdef ALPHA_TEST
    if (alpha < AlphaCutoff) { discard; }
#endif
    float3 specular = SpecularColor.rgb * SpecularMap.Sample(MainSampler, input.uv).rgb;
    float  exponent = max(Shininess, 1.0);
    float3 emissive = EmissiveColor.rgb * EmissiveMap.Sample(MainSampler, input.uv).rgb;

    float3 viewPos   = mul(float4(input.worldPos, 1.0), View).xyz;
    float  viewDepth = -viewPos.z;   // cascade selection + cluster lookup

    float3 Lo = float3(0.0, 0.0, 0.0);
    LightList lights = LightsAt(input.clip.xy, viewDepth);
    for (uint i = 0; i < lights.count; ++i) {
        GpuLight light = LightAt(lights, i);
        Lo += PhongLight(light, input.worldPos, N, V, diffuse, specular, exponent) * ShadowOf(light, input.worldPos, N, viewDepth);
    }
    // The scene's diffuse ambient: the sky's irradiance when it lights the scene, plus the flat fill.
    float3 ambient = diffuse * Ambient;
    if (IBLMaxLod >= 0.0) {
        ambient += diffuse * (EvalSH9(N) / PI) * IblDiffuse;
    }
    float3 litColor = ambient + Lo + emissive;

    // For the views that look at the surface's makings: a Phong surface as the dielectric it is, as
    // rough as its highlight is broad.
    const float roughness = saturate(sqrt(2.0 / (exponent + 2.0)));
    uint debugMode = (uint)(DebugParams.x + 0.5);
    if (debugMode != 0u) {
        litColor = DebugSemanticColor(debugMode, diffuse, N, roughness, 0.0, viewDepth, lights.count, litColor);
#ifdef GBUFFER
        alpha = 1.0;
#endif
    }
#ifdef GBUFFER
    GBufferOutput o;
    o.color    = float4(litColor, alpha);
    o.normal   = OctEncode(normalize(mul(float4(N, 0.0), View).xyz));
    o.velocity = MotionVector(input.curClip, input.prevClip);
    // SSR reads these: Phong reflects nothing of its surroundings (its highlight is the lights'),
    // so it is written fully rough and never metal, and SSR passes it by, as Unlit; SSGI's bounce
    // lands on its diffuse.
    o.material = float2(1.0, 0.0);
    o.albedo   = float4(diffuse, 1.0);
    return o;
#else
    return float4(litColor, alpha);   // color-only (transparent pass): alpha drives AlphaBlend
#endif
}
