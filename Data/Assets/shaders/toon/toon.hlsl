// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// The toon sample's shader (Code/Samples/Samples.CustomShader), both stages in one file: VSMain and PSMain,
// each registered by name. Cel shading in hard bands, a shadow colour and a rim light, in place of
// the engine's PBR. A LOW-LEVEL custom shader forks the whole lighting and keeps the frame's
// contract:
//   - the vertex stage: the mesh vertex in, VSOutput out, the SKINNED / INSTANCED / WIND variants.
//     The engine's forward vertex library is exactly that, so VSMain is it, under its own name.
//   - the pixel stage: the View constants, lights, shadow maps and clusters (sets 0 and 3) declared
//     as forward.ps.hlsl declares them, its own material block in set 2 (laid out by the material's
//     properties, in order), and under GBUFFER the five targets the post stack reads (colour, view
//     normal, motion vector, roughness/metallic, albedo).
// Ported from the previous engine's RenderMaterialsCustom sample.

// ==== The vertex stage ====
#define FORWARD_VS_ENTRY VSMain
#include "forward_vs.hlsli"

// ==== The rest of the frame (sets 0 and 3): as forward.ps.hlsl declares it (the View constants
// came with forward_vs.hlsli) ====
#include "depth.hlsli"
struct GpuLight {                            // matches render::GpuLight (64 bytes)
    float3 positionWS; float range;
    float3 color;      float intensity;
    float3 directionWS;float type;           // 0=Directional, 1=Point, 2=Spot
    float innerCos; float outerCos; float shadowIndex;   // shadowIndex >= 0 -> casts shadow
    float shadowStrength;                              // 1 = full shadow, 0 = none
};
StructuredBuffer<GpuLight> Lights : register(t0, space0);
// CSM cascade depth ARRAY (t1, one layer per cascade) + a comparison sampler (s0) for hardware PCF.
Texture2DArray         ShadowMap     : register(t1, space0);
SamplerComparisonState ShadowSampler : register(s0, space0);

// IBL: SH9 diffuse irradiance coeffs (t5), prefiltered specular cube (t6), BRDF LUT (t7),
// + a linear env sampler (s1). Diffuse uses spherical harmonics (no irradiance cube). Active only
// when IBLMaxLod >= 0 (else the neutral dummies are bound and the flat-ambient path runs).
StructuredBuffer<float4> IblSH       : register(t5, space0);
TextureCube              PrefilterMap : register(t6, space0);
Texture2D                BRDFLut      : register(t7, space0);
SamplerState             EnvSampler   : register(s1, space0);
// Reflection probes: a cube-ARRAY of prefiltered probe radiance (t8) + a probe metadata buffer
// (t9). ProbeCenter.w carries the probe COUNT; the forward loops Probes[0..count], box-tests + parallax-
// projects + blends each by an influence weight (blendDistance falloff) over the global IBL.
TextureCubeArray         ProbeArray   : register(t8, space0);
struct GpuProbe {
    float4 center;   // xyz = capture center, w = intensity
    float4 boxMin;   // xyz = box min,        w = blendDistance
    float4 boxMax;   // xyz = box max,        w = cube slice (array index)
    float4 params;   // x = mipCount, y = priority, z = parallax (0/1), w = pad
};
StructuredBuffer<GpuProbe> Probes : register(t9, space0);

// Evaluate the 9-coefficient SH irradiance in direction n (Ramamoorthi/Hanrahan cosine-convolved).
float3 EvalSH9(float3 n) {
    float3 r = IblSH[0].rgb * 0.886227;                       // l=0
    r += IblSH[1].rgb * (2.0 * 0.511664 * n.y);              // l=1
    r += IblSH[2].rgb * (2.0 * 0.511664 * n.z);
    r += IblSH[3].rgb * (2.0 * 0.511664 * n.x);
    r += IblSH[4].rgb * (2.0 * 0.429043 * n.x * n.y);        // l=2
    r += IblSH[5].rgb * (2.0 * 0.429043 * n.y * n.z);
    r += IblSH[6].rgb * (0.743125 * (3.0 * n.z * n.z - 1.0));
    r += IblSH[7].rgb * (2.0 * 0.429043 * n.x * n.z);
    r += IblSH[8].rgb * (0.429043 * (n.x * n.x - n.y * n.y));
    return max(r, 0.0);
}

static const float kShadowTexel = 1.0 / 1024.0;   // 1 / shadow resolution

// Sample one cascade with a normal-offset bias (scaled by the cascade's world texel size, fading at
// grazing angles) + 3x3 hardware PCF on its array layer. 1 = lit, 0 = fully shadowed.
float SampleCascade(int cascade, float3 worldPos, float3 N, float NdotL) {
    float texelWorld = CascadeTexelSize[cascade];
    // Normal-offset bias: push along the surface normal, scaled by the cascade's world texel size and
    // FADING TO ZERO as the surface faces the light (1 - NdotL). Face-on receivers get ~no offset (so
    // no visible gap at contacts); only grazing surfaces, where acne is worst, get the full push.
    float3 biasedPos = worldPos + N * (ShadowNormalBias * texelWorld * (1.0 - NdotL));
    float4 lc  = mul(float4(biasedPos, 1.0), CascadeViewProj[cascade]);
    if (lc.w <= 0.0) { return 1.0; }
    float3 ndc = lc.xyz / lc.w;
    // uv.y sign is backend-driven (ShadowParams.y): -1 on Vulkan (neg viewport), +1 on Y-flip targets.
    float2 uv  = float2(ndc.x * 0.5 + 0.5, ndc.y * ShadowParams.y * 0.5 + 0.5);
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) { return 1.0; }
    float compareDepth = BiasTowardViewer(ndc.z, ShadowDepthBias);   // toward the light: fewer false occluders
    float layer = CascadeLayerBase + (float)cascade;   // this view's slice of the shared array
    float sum = 0.0;
    [unroll] for (int y = -1; y <= 1; ++y) {
        [unroll] for (int x = -1; x <= 1; ++x) {
            sum += ShadowMap.SampleCmpLevelZero(ShadowSampler, float3(uv + float2(x, y) * kShadowTexel, layer), compareDepth);
        }
    }
    return sum * (1.0 / 9.0);
}

// Cascaded shadow: pick the cascade by view-space depth, sample it, and blend into the next cascade
// over the last 15% of the range (hides the cascade seam).
float SampleCSM(float3 worldPos, float3 N, float NdotL, float viewDepth) {
    int count = (int)ShadowCascadeCount;
    if (count <= 0) { return 1.0; }

    int cascade = count - 1;
    [unroll] for (int i = 0; i < CASCADE_COUNT; ++i) {
        if (i < count && viewDepth < CascadeSplitFar[i]) { cascade = i; break; }
    }

    float shadow = SampleCascade(cascade, worldPos, N, NdotL);

    float splitFar  = CascadeSplitFar[cascade];
    float splitNear = (cascade == 0) ? 0.0 : CascadeSplitFar[cascade - 1];
    float blendBand = (splitFar - splitNear) * 0.15;
    if (cascade < count - 1 && viewDepth > splitFar - blendBand) {
        float t = saturate((viewDepth - (splitFar - blendBand)) / max(blendBand, 1e-4));
        shadow = lerp(shadow, SampleCascade(cascade + 1, worldPos, N, NdotL), t);
    }

    // Far fade: dissolve shadow toward fully-lit as viewDepth approaches the last cascade's far edge
    // (the shadow distance). Without this the coverage boundary is a hard line -- on a tilted camera
    // it reads as a diagonal where directional shadows pop in/out while rotating. ShadowParams.x is a
    // fixed fade WIDTH in world units (distance-independent), so the soft edge is the same physical
    // thickness whatever the reach.
    float shadowFar = CascadeSplitFar[count - 1];
    float fadeBand  = max(ShadowParams.x, 0.5);
    float farFade   = saturate((shadowFar - viewDepth) / fadeBand);
    shadow = lerp(1.0, shadow, farFade);
    return shadow;
}

// Local-light (spot/point) shadows: a shared 2D depth ATLAS (t2) + per-light entries (t3). Each entry
// is a perspective world->light-clip matrix + the uv scale/bias of its tile in the atlas. Reuses the
// comparison sampler. GpuLight.shadowIndex selects the entry (point lights use 6 faces in 5.3b).
Texture2DArray ShadowAtlas : register(t2, space0);   // layer 0 = realtime, layer 1 = static (cached)
struct GpuLocalShadow {
    row_major float4x4 viewProj;
    float4 atlasScaleBias;       // xy = uv scale, zw = uv offset
    float  depthBias; float atlasSelect;   // atlasSelect = atlas array layer
    float  normalBiasPerDistance; float _localPad;   // the light's normal offset, world units per unit distance
};
StructuredBuffer<GpuLocalShadow> LocalShadows : register(t3, space0);

static const float kAtlasTexel = 1.0 / 2048.0;   // 1 / atlas resolution

// Sample one local-shadow entry: project into its light clip, map the clip uv into the entry's atlas
// tile (on its array layer), 3x3 PCF. 1 = lit, 0 = shadowed. The receiver is pushed along its normal
// by the light's normal offset (its tile texels at this distance), fading as it faces the light, as
// SampleCascade does.
float SampleLocalShadow(int idx, float3 worldPos, float3 N, float3 lightPos) {
    GpuLocalShadow s = LocalShadows[idx];
    if (s.atlasScaleBias.x <= 0.0) { return 1.0; }   // degenerate entry (no atlas tile) -> unshadowed
    float3 toLight = lightPos - worldPos;
    float dist = length(toLight);
    float NdotL = saturate(dot(N, toLight / max(dist, 1e-4)));
    float3 biasedPos = worldPos + N * (s.normalBiasPerDistance * dist * (1.0 - NdotL));
    float4 lc = mul(float4(biasedPos, 1.0), s.viewProj);
    if (lc.w <= 0.0) { return 1.0; }
    float3 ndc = lc.xyz / lc.w;
    float2 uv  = float2(ndc.x * 0.5 + 0.5, ndc.y * ShadowParams.y * 0.5 + 0.5);   // backend-driven uv.y sign
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0 || ndc.z < 0.0 || ndc.z > 1.0) { return 1.0; }   // outside the light's depth range
    float2 atlasUV = uv * s.atlasScaleBias.xy + s.atlasScaleBias.zw;
    float compareDepth = BiasTowardViewer(ndc.z, s.depthBias);
    float sum = 0.0;
    [unroll] for (int y = -1; y <= 1; ++y) {
        [unroll] for (int x = -1; x <= 1; ++x) {
            sum += ShadowAtlas.SampleCmpLevelZero(ShadowSampler, float3(atlasUV + float2(x, y) * kAtlasTexel, s.atlasSelect), compareDepth);
        }
    }
    return sum * (1.0 / 9.0);
}

// Pick a point light's cube face (0=+X,1=-X,2=+Y,3=-Y,4=+Z,5=-Z) from the light->fragment direction
// - the dominant axis. Matches BuildPointShadowFace's face ordering.
int CubeFace(float3 dir) {
    float3 a = abs(dir);
    if (a.x >= a.y && a.x >= a.z) { return dir.x > 0.0 ? 0 : 1; }
    if (a.y >= a.z)               { return dir.y > 0.0 ? 2 : 3; }
    return dir.z > 0.0 ? 4 : 5;
}

// Shadow attenuation for a shadowed light (caller checks shadowIndex >= 0): directional -> CSM,
// point -> the cube face of the atlas, spot -> the single atlas tile.
// The light's shadow strength lerps the result toward lit (0 = no darkening, 1 = full).
float ShadowFactor(GpuLight L, float3 worldPos, float3 N, float viewDepth) {
    float shadow;
    if (L.type < 0.5) { shadow = SampleCSM(worldPos, N, saturate(dot(N, -L.directionWS)), viewDepth); }   // directional
    else {
        int base = (int)LocalShadowBase + (int)L.shadowIndex;
        int entry = (L.type < 1.5) ? base + CubeFace(worldPos - L.positionWS) : base;   // point: 6 faces; spot: 1 tile
        shadow = SampleLocalShadow(entry, worldPos, N, L.positionWS);
    }
    return lerp(1.0, shadow, saturate(L.shadowStrength));
}

// Clustered light culling (set 3): per-cluster (offset,count) + the flat light-index list. When
// ClusterGridX == 0 (clustering unavailable) the shader falls back to looping all lights.
StructuredBuffer<uint2> ClusterOffsets      : register(t0, space3);
StructuredBuffer<uint>  ClusterLightIndices : register(t1, space3);

// Maps a fragment's screen position + positive view-space depth to a linear cluster index.
uint ClusterIndex(float2 screenPos, float viewDepth) {
    // SV_Position is in full-target pixels; the grid is viewport-local, so subtract the offset.
    float2 local = screenPos - float2((float)ClusterVpX, (float)ClusterVpY);
    uint tileX = (uint)local.x / ClusterTileSize;
    float screenH = (float)(ClusterGridY * ClusterTileSize);
    uint tileY = (uint)((screenH - local.y) / ClusterTileSize);   // flip Y (SV_Position y=0 at top)
    tileX = min(tileX, ClusterGridX - 1);
    tileY = min(tileY, ClusterGridY - 1);
    float logDepth = log(max(viewDepth, ClusterNear));
    int slice = (int)(logDepth * ClusterLogScale + ClusterLogBias);
    slice = clamp(slice, 0, (int)ClusterSliceCount - 1);
    return tileX + tileY * ClusterGridX + (uint)slice * ClusterGridX * ClusterGridY;
}
// ==== The toon material (set 2): laid out by the material's properties, in their order ====
cbuffer Material : register(b0, space2) {
    float4 BaseColor;        // offset 0
    float4 ShadowColor;      // 16: the colour of the unlit side
    float4 RimColor;         // 32
    float  Bands;            // 48: how many steps the light falls into
    float  RimPower;         // 52: how tight the rim is
    float  RimIntensity;     // 56
    float  AlphaCutoff;      // 60: ALPHA_TEST threshold
};
Texture2D    AlbedoMap   : register(t0, space2);
SamplerState MainSampler : register(s0, space2);


// ==== Toon shading ====

// The light reaching a surface, cut into `Bands` hard steps (0 = the shadow side, 1 = fully lit).
float Quantize(float value, float bands) {
    float b = max(bands, 1.0);
    return saturate(floor(value * b + 0.5) / b);
}

// Range window and spot cone as the engine's lights use them (forward.ps.hlsl), so a toon surface
// is lit by the same lights over the same reach; only the response is stylised.
float Attenuation(float dist, float range) {
    if (range <= 0.0) return 1.0;
    float d  = dist / range;
    float d2 = d * d;
    float win = saturate(1.0 - d2 * d2);
    return (win * win) / (dist * dist + 1e-4);
}
float SpotAttenuation(float3 L, float3 spotDir, float innerCos, float outerCos) {
    float cosA = dot(-L, spotDir);
    return saturate((cosA - outerCos) / (innerCos - outerCos + 1e-4));
}

// One light's toon contribution: the banded diffuse between the shadow colour and the albedo.
float3 ToonLight(GpuLight light, float3 worldPos, float3 N, float3 albedo, float shadow) {
    float3 L; float atten = 1.0;
    if (light.type < 0.5) {
        L = -light.directionWS;
    } else {
        float3 toLight = light.positionWS - worldPos;
        float  dist    = length(toLight);
        L = toLight / max(dist, 1e-4);
        atten = Attenuation(dist, light.range);
        if (light.type > 1.5) {
            atten *= SpotAttenuation(L, light.directionWS, light.innerCos, light.outerCos);
        }
    }
    float lit = Quantize(saturate(dot(N, L)) * shadow, Bands);
    float3 tone = lerp(ShadowColor.rgb * albedo, albedo, lit);
    return tone * light.color * light.intensity * saturate(atten);
}

// Octahedral encode a unit vector -> [-1,1]^2 (full sphere, no sign ambiguity). Used to pack the
// view-space normal into the RG16F G-buffer target for the post stack (GTAO/TAA).
float2 OctEncode(float3 n) {
    n /= (abs(n.x) + abs(n.y) + abs(n.z));
    float2 e = n.xy;
    if (n.z < 0.0) { e = (1.0 - abs(float2(e.y, e.x))) * float2(e.x >= 0.0 ? 1.0 : -1.0, e.y >= 0.0 ? 1.0 : -1.0); }
    return e;
}

#ifdef GBUFFER
struct PSOutput {
    float4 color    : SV_Target0;
    float2 normal   : SV_Target1;
    float2 velocity : SV_Target2;
    float2 material : SV_Target3;
    float4 albedo   : SV_Target4;
};
PSOutput PSMain(VSOutput input) {
#else
float4 PSMain(VSOutput input) : SV_Target0 {
#endif
#ifdef DITHER
    static const float kBayer[16] = { 0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5 };
    uint2 cell = uint2(input.clip.xy) & 3u;
    if (input.fade > (kBayer[cell.y * 4u + cell.x] + 0.5) / 16.0) { discard; }
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

    if (ClusterGridX == 0) {
        uint count = (uint)LightCount;
        for (uint i = 0; i < count; ++i) {
            GpuLight L = Lights[LightOffset + i];
            float shadow = (L.shadowIndex >= 0.0) ? ShadowFactor(L, input.worldPos, N, viewDepth) : 1.0;
            color += ToonLight(L, input.worldPos, N, albedo, shadow);
        }
    } else {
        uint  cluster = ClusterIndex(input.clip.xy, viewDepth);
        uint2 oc = ClusterOffsets[cluster];
        for (uint ci = 0; ci < oc.y; ++ci) {
            GpuLight L = Lights[LightOffset + ClusterLightIndices[oc.x + ci]];
            float shadow = (L.shadowIndex >= 0.0) ? ShadowFactor(L, input.worldPos, N, viewDepth) : 1.0;
            color += ToonLight(L, input.worldPos, N, albedo, shadow);
        }
    }

    // Rim light: a bright edge where the surface turns away from the eye.
    float rim = pow(1.0 - saturate(dot(N, V)), max(RimPower, 0.01));
    color += RimColor.rgb * rim * RimIntensity;

#ifdef GBUFFER
    float2 curNDC  = input.curClip.xy  / input.curClip.w  + Jitter.xy;
    float2 prevNDC = input.prevClip.xy / input.prevClip.w + Jitter.zw;
    PSOutput o;
    o.color    = float4(color, alpha);
    o.normal   = OctEncode(normalize(mul(float4(N, 0.0), View).xyz));
    o.velocity = (curNDC - prevNDC) * float2(0.5, -0.5);   // TAA reprojects with this
    o.material = float2(1.0, 0.0);                          // fully rough, not metal: SSR skips it
    o.albedo   = float4(albedo, 1.0);                       // SSGI tints its bounce by it
    return o;
#else
    return float4(color, alpha);
#endif
}
