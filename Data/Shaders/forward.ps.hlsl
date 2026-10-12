// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// variants: ALPHA_TEST GBUFFER DITHER
#include "lighting.hlsli"
#include "forward_ps.hlsli"
cbuffer Material : register(b0, space2) {    // data-driven PBR material (inferred from properties)
    float4 BaseColor;
    float  Metallic;
    float  Roughness;
    float  WindStrength;       // the vertex sway (wind.hlsli); the fragment never reads a Wind lane
    float  WindSpeed;
    float4 EmissiveColor;      // rgb x EmissiveMap = emitted radiance (offset 32)
    float  OcclusionStrength;  // 0..1 blend toward the sampled AO (glTF occlusionStrength; offset 48)
    float  NormalScale;        // scales the tangent-space XY perturbation (glTF normalScale)
    float  AlphaCutoff;        // ALPHA_TEST threshold (glTF alphaCutoff; 0.5 = the spec default)
    float  WindHeight;         // the vertex sway's height mask (wind.hlsli)
    // (pre-straggler materials upgrade at load: emissive black, strength/scale 1, cutoff 0.5)
};
// Standard PBR material maps (the fixed forward set-2 contract, Sedulous-aligned). Unset maps bind a
// neutral default (flat normal for NormalMap, white for the rest, EmissiveMap too: its factor
// EmissiveColor is black unless the material glows) so untextured materials are unaffected. All
// five are sampled: albedo, normal (tangent-space), metallic-roughness (glTF: G=roughness,
// B=metallic), occlusion, emissive.
Texture2D    AlbedoMap            : register(t0, space2);
Texture2D    NormalMap            : register(t1, space2);
Texture2D    MetallicRoughnessMap : register(t2, space2);
Texture2D    OcclusionMap         : register(t3, space2);
Texture2D    EmissiveMap          : register(t4, space2);
SamplerState MainSampler          : register(s0, space2);
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


// Forward outputs. GBUFFER (opaque/masked MRT pass): shaded color + view-normal + motion vector.
// Otherwise (the color-only transparent pass): just the blended color.
// Editor semantic debug views (DebugParams.x, ViewDebugSemantic; 0 = off). A uniform
// branch - every lane takes the same path, free when off; kept out of Material/variant
// space on purpose (the drift lint never sees it). Values are meant to reach the screen
// RAW (the compose blits scene color past tonemap when a semantic mode is active).
float3 DebugSemanticColor(uint mode, float3 albedo, float3 N, float roughness, float metallic,
                          float viewDepth, uint lightCount, float3 lit) {
    if (mode == 1u) { return albedo; }
    if (mode == 2u) { return N * 0.5 + 0.5; }
    if (mode == 3u) { return roughness.xxx; }
    if (mode == 4u) { return metallic.xxx; }
    if (mode == 5u) {
        // CSM cascade selection tinted over albedo luma (red/green/blue/yellow, grey = no shadow).
        float luma = dot(albedo, float3(0.299, 0.587, 0.114));
        int count = (int)ShadowCascadeCount;
        float3 tint = float3(0.55, 0.55, 0.55);
        if (count > 0) {
            int cascade = count - 1;
            [unroll] for (int i = 0; i < 4; ++i) {
                if (i < count && viewDepth < CascadeSplitFar[i]) { cascade = i; break; }
            }
            const float3 tints[4] = { float3(1.0, 0.3, 0.3), float3(0.3, 1.0, 0.3),
                                      float3(0.3, 0.5, 1.0), float3(1.0, 1.0, 0.3) };
            tint = tints[cascade];
        }
        return tint * (0.35 + 0.65 * luma);
    }
    if (mode == 6u) {
        // Light-count heatmap: 0 = deep blue, 8+ = red (the per-cluster budget scale).
        float t = saturate((float)lightCount / 8.0);
        return lerp(float3(0.05, 0.05, 0.6), float3(1.0, 0.1, 0.05), t);
    }
    if (mode == 7u) {
        // Overbright/invalid: magenta where the lit result is not plausibly finite
        // (NaN fails every comparison, so !(x < limit) catches NaN and +inf both).
        float m = max(lit.r, max(lit.g, lit.b));
        bool bad = !(m < 1e30) || !(m >= 0.0);
        float luma = saturate(dot(lit, float3(0.299, 0.587, 0.114)));
        return bad ? float3(1.0, 0.0, 1.0) : luma.xxx;
    }
    return lit;
}

#ifdef GBUFFER
GBufferOutput main(PSInput input) {
#else
float4 main(PSInput input) : SV_Target0 {
#endif
#ifdef DITHER
    ScreenDoorFade(input.clip.xy, input.fade);
#endif
    // Tangent-space normal mapping. The flat default (0.5, 0.5, 1) decodes to (0,0,1) = the
    // geometric normal, so untextured materials are untouched. tangentWS.w carries the TBN
    // handedness (glTF convention), so mirrored-UV geometry lights correctly. Degenerate
    // tangents fall back to the geometric normal.
    float3 N = normalize(input.normalWS);
    {
        // Sample the normal map in UNIFORM control flow (hoisted out of the tangent-validity branch
        // below). WGSL/Chrome make an implicit-derivative sample inside a per-pixel branch a hard error;
        // sampling unconditionally keeps the mip-selecting derivatives (a material texture, unlike the
        // full-screen post taps) and is harmless when the tangent is degenerate - the flat default map
        // decodes to (0,0,1) and the result is simply unused (N stays the geometric normal).
        float3 nTex = NormalMap.Sample(MainSampler, input.uv).xyz * 2.0 - 1.0;
        float3 T = input.tangentWS.xyz - N * dot(input.tangentWS.xyz, N);   // Gram-Schmidt re-orthogonalize
        float  tLen = length(T);
        if (tLen > 1e-4) {
            T /= tLen;
            float3 B = cross(N, T) * input.tangentWS.w;   // handedness: mirrored UVs flip the bitangent
            nTex.xy *= NormalScale;   // authored bump strength (1 = as-authored)
            N = normalize(nTex.x * T + nTex.y * B + nTex.z * N);
        }
    }
    float3 V = normalize(CameraPos - input.worldPos);

    float4 albedoTex = AlbedoMap.Sample(MainSampler, input.uv);
    float3 albedo    = input.color.rgb * BaseColor.rgb * albedoTex.rgb;
    float  alpha     = saturate(input.color.a * BaseColor.a * albedoTex.a);   // surface opacity (alpha blend)
#ifdef ALPHA_TEST
    // Masked geometry: cut out sub-cutoff fragments before shading (skips lighting + writes no depth/
    // G-buffer for the hole). The cutoff is authored (glTF alphaCutoff; 0.5 default).
    if (alpha < AlphaCutoff) { discard; }
#endif
    float2 mr        = MetallicRoughnessMap.Sample(MainSampler, input.uv).gb;   // glTF: G=roughness, B=metallic
    float  metallic  = saturate(Metallic * mr.y);
    float  roughness = clamp(Roughness * mr.x, 0.045, 1.0);
    float3 F0        = lerp(float3(0.04, 0.04, 0.04), albedo, metallic);

    float3 viewPos   = mul(float4(input.worldPos, 1.0), View).xyz;
    float  viewDepth = -viewPos.z;                             // cascade selection + cluster lookup

    uint debugLightCount;   // ClusterHeat: the lights evaluated here
    float3 Lo = DirectLight(input.clip.xy, input.worldPos, viewDepth, N, V, albedo, roughness,
                            metallic, F0, debugLightCount);

    float  ao = lerp(1.0, OcclusionMap.Sample(MainSampler, input.uv).r, OcclusionStrength);
    float3 ambient = AmbientLight(input.worldPos, N, V, albedo, roughness, metallic, F0, ao);
#ifdef GBUFFER
    // Emitted radiance: factor x map, added unlit on top (HDR - feeds bloom). The factor defaults
    // to black (no glow) and an unbound map to white (glTF), so a colour alone glows.
    float3 emissive = EmissiveColor.rgb * EmissiveMap.Sample(MainSampler, input.uv).rgb;
    float2 velocity = MotionVector(input.curClip, input.prevClip);

    GBufferOutput o;
    float3 litColor = ambient + Lo + emissive;
    uint debugMode = (uint)(DebugParams.x + 0.5);
    if (debugMode != 0u) {
        litColor = DebugSemanticColor(debugMode, albedo, N, roughness, metallic, viewDepth,
                                      debugLightCount, litColor);
        alpha = 1.0;
    }
    o.color    = float4(litColor, alpha);
    o.normal   = OctEncode(normalize(mul(float4(N, 0.0), View).xyz));   // view-space MAPPED normal (octahedral)
    o.velocity = velocity;
    o.material = float2(roughness, metallic);   // SSR reads these to gate/fade reflections
    // The diffuse albedo the ambient term used (a metal reflects no diffuse light): SSGI's bounce
    // is light arriving at the surface, and what leaves it is that times this.
    o.albedo   = float4(albedo * (1.0 - metallic), 1.0);
    return o;
#else
    float3 emissive = EmissiveColor.rgb * EmissiveMap.Sample(MainSampler, input.uv).rgb;
    float3 litColor = ambient + Lo + emissive;
    uint debugMode = (uint)(DebugParams.x + 0.5);
    if (debugMode != 0u) {
        litColor = DebugSemanticColor(debugMode, albedo, N, roughness, metallic, viewDepth,
                                      debugLightCount, litColor);
    }
    return float4(litColor, alpha);   // color-only (transparent pass): alpha drives AlphaBlend
#endif
}
