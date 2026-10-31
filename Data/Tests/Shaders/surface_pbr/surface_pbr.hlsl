// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The engine's built-in PBR (`forward`) written as a lit surface shader: the reference that a
// surface shader renders as the engine's own does (Sedulous.Integration.Shaders compares them on
// the GPU). Its properties are forward's, in forward's order, so a PBR material's values mean the
// same on it; its Vertex() is forward's wind sway.
// surface: lit

#include "wind_sway.hlsli"

properties
{
    Color    BaseColor         = (1, 1, 1, 1);
    float    Metallic          = 0   [0, 1];
    float    Roughness         = 0.5 [0, 1];
    float    WindStrength      = 0;
    float    WindSpeed         = 1;
    ColorHdr EmissiveColor     = (0, 0, 0, 1);
    float    OcclusionStrength = 1   [0, 1];
    float    NormalScale       = 1   [0, 2];
    float    AlphaCutoff       = 0.5 [0, 1];
    float    WindHeight        = 1;
    Texture  AlbedoMap;
    Texture  NormalMap;
    Texture  MetallicRoughnessMap;
    Texture  OcclusionMap;
    Texture  EmissiveMap;
    Sampler  MainSampler;
}

void Surface(SurfaceInput input, inout SurfaceOutput surface) {
    float3 nTex = NormalMap.Sample(MainSampler, input.uv).xyz * 2.0 - 1.0;
    nTex.xy *= NormalScale;
    surface.normal = nTex;
    float4 albedoTex = AlbedoMap.Sample(MainSampler, input.uv);
    surface.albedo = input.color.rgb * BaseColor.rgb * albedoTex.rgb;
    surface.alpha  = input.color.a * BaseColor.a * albedoTex.a;
    float2 mr = MetallicRoughnessMap.Sample(MainSampler, input.uv).gb;   // glTF: G=roughness, B=metallic
    surface.metallic  = Metallic * mr.y;
    surface.roughness = Roughness * mr.x;
    surface.occlusion = lerp(1.0, OcclusionMap.Sample(MainSampler, input.uv).r, OcclusionStrength);
    surface.emissive  = EmissiveColor.rgb * EmissiveMap.Sample(MainSampler, input.uv).rgb;
}

void Vertex(inout VertexInput v) {
    v.position += WindSwayOf(v.position, v.localPosition.y, Time(), WindStrength, WindSpeed,
                             WindHeight);
}
