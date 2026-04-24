// Forward PBR Fragment Shader
// Cook-Torrance BRDF with directional, point, and spot lights.
// Material layout matches Materials.CreatePBR() uniform buffer.

#pragma pack_matrix(row_major)

static const float PI = 3.14159265359;

// Set 0: Frame data
cbuffer SceneUniforms : register(b0, space0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
    float4x4 ViewProjectionMatrix;
    float4x4 InvViewMatrix;
    float4x4 InvProjectionMatrix;
    float4x4 InvViewProjectionMatrix;
    float4x4 PrevViewProjectionMatrix;
    float3 CameraPosition;
    float NearPlane;
    float FarPlane;
    float Time;
    float DeltaTime;
    float _Pad0;
    float2 ScreenSize;
    float2 InvScreenSize;
};

cbuffer LightParams : register(b1, space0)
{
    uint LightCount;
    float3 AmbientColor;
};

struct GPULight
{
    float3 Position;
    float Type;       // 0=directional, 1=point, 2=spot
    float3 Direction;
    float Range;
    float3 Color;     // pre-multiplied by intensity
    float Intensity;
    float InnerConeAngle; // cos(angle)
    float OuterConeAngle; // cos(angle)
    float ShadowBias;
    int   ShadowIndex;    // -1 = no shadow, else index into ShadowData
};

StructuredBuffer<GPULight> Lights : register(t0, space0);

// Set 4: Shadow data
struct GPUShadowData
{
    float4x4 LightViewProj;
    float4   AtlasUVRect;       // (u, v, w, h) within the atlas in [0,1]
    float4   CascadeSplits;     // view-space far depth per cascade (base entry only)
    float    Bias;
    float    NormalBias;        // in texels, scaled by WorldTexelSize in shader
    float    InvShadowMapSize;
    int      CascadeCount;      // > 0 only on the base entry of a cascaded directional
    float    WorldTexelSize;    // world units per shadow map texel
    float3   _Pad;
};

Texture2D                 ShadowAtlas  : register(t0, space4);
SamplerComparisonState    ShadowSampler : register(s0, space4);
StructuredBuffer<GPUShadowData> ShadowData : register(t1, space4);

// Picks a cube face index (0..5) from the world-space direction from the light
// to the surface. Face order matches ShadowMatrices.PointLightFaceViewProj:
// 0 = +X, 1 = -X, 2 = +Y, 3 = -Y, 4 = +Z, 5 = -Z.
int PickPointFace(float3 toFragment)
{
    float3 absD = abs(toFragment);
    if (absD.x >= absD.y && absD.x >= absD.z)
        return toFragment.x > 0.0 ? 0 : 1;
    if (absD.y >= absD.z)
        return toFragment.y > 0.0 ? 2 : 3;
    return toFragment.z > 0.0 ? 4 : 5;
}

// Samples a SINGLE shadow map entry (one cascade or one face) and returns the
// lit fraction (1 = lit, 0 = shadowed). Extracted so cascade blending can call
// it twice - once for the primary cascade and once for the adjacent one.
//
// Matches the legacy Sedulous renderer:
//   - Receiver lookup with normal-offset bias scaled by world-space texel size
//   - saturate(z) instead of rejection (avoids popping at cascade far)
//   - Plain 5×5 box PCF (hardware depth bias prevents acne, not the shader)
float SampleShadowEntry(GPUShadowData shadow, float3 worldPos, float3 worldNormal, float NdotL)
{
    // Normal-offset bias in world space: NormalBias is in texels, scale by the
    // cascade's world texel size, and fade at grazing angles (NdotL -> 0).
    float3 biasedPos = worldPos + worldNormal * (shadow.NormalBias * shadow.WorldTexelSize * (1.0 - NdotL));

    float4 lightClip = mul(float4(biasedPos, 1.0), shadow.LightViewProj);
    if (lightClip.w <= 0.0) return 1.0;

    float3 lightNDC = lightClip.xyz / lightClip.w;

    // NDC -> shadow map UV (DX-style: y inverted). saturate lets fragments just past
    // the far plane still sample (clamped) rather than popping to fully-lit.
    float2 shadowUV = float2(lightNDC.x * 0.5 + 0.5, -lightNDC.y * 0.5 + 0.5);
    if (any(shadowUV < 0.0) || any(shadowUV > 1.0))
        return 1.0;
    float compareDepth = saturate(lightNDC.z) - shadow.Bias;

    // Local UV -> atlas UV.
    float2 atlasUV = shadow.AtlasUVRect.xy + shadowUV * shadow.AtlasUVRect.zw;

    // Plain 5×5 box PCF. 25 hardware comparison taps -> 100 effective bilinear
    // samples. Hardware depth bias in the shadow pipeline prevents acne so the
    // regular grid pattern doesn't produce banding.
    float2 texel = shadow.AtlasUVRect.zw * shadow.InvShadowMapSize;
    float result = 0.0;
    [unroll]
    for (int y = -2; y <= 2; y++)
    {
        [unroll]
        for (int x = -2; x <= 2; x++)
        {
            float2 offset = float2(x, y) * texel;
            result += ShadowAtlas.SampleCmpLevelZero(ShadowSampler, atlasUV + offset, compareDepth);
        }
    }
    return result / 25.0;
}

// Returns the cascade split depth for a given cascade index (0-based).
float GetCascadeSplit(float4 splits, int idx)
{
    if (idx == 0) return splits.x;
    if (idx == 1) return splits.y;
    if (idx == 2) return splits.z;
    return splits.w;
}

// Samples a shadow map with cascade/face selection and cascade blending.
//
// Handles three light types:
//   - Directional: cascade selection by view-space depth, blended at boundaries
//   - Spot:        single shadow map, direct sample
//   - Point:       cube face selection by direction from light to fragment
float SampleShadow(GPULight light, float3 worldPos, float3 worldNormal, float NdotL, float viewDepth)
{
    int shadowIndex = light.ShadowIndex;
    if (shadowIndex < 0) return 1.0;

    GPUShadowData baseShadow = ShadowData[shadowIndex];

    // --- Spot lights (CascadeCount == 0): single entry, sample directly ---
    if (baseShadow.CascadeCount <= 0)
        return SampleShadowEntry(baseShadow, worldPos, worldNormal, NdotL);

    // --- Point lights: face selection, no blending ---
    if (light.Type > 0.5 && light.Type < 1.5)
    {
        float3 toFrag = worldPos - light.Position;
        int faceIdx = PickPointFace(toFrag);
        return SampleShadowEntry(ShadowData[shadowIndex + faceIdx], worldPos, worldNormal, NdotL);
    }

    // --- Directional lights: cascade selection with smooth blending ---
    int cascadeCount = baseShadow.CascadeCount;
    float4 splits = baseShadow.CascadeSplits;

    int cascadeIdx = cascadeCount - 1;
    if (viewDepth < splits.x)      cascadeIdx = 0;
    else if (viewDepth < splits.y) cascadeIdx = 1;
    else if (viewDepth < splits.z) cascadeIdx = 2;
    else if (viewDepth < splits.w) cascadeIdx = 3;

    // Sample the primary cascade.
    float primary = SampleShadowEntry(ShadowData[shadowIndex + cascadeIdx], worldPos, worldNormal, NdotL);

    // Blend zone: the last 15% of each cascade's depth range transitions
    // smoothly into the next cascade, eliminating the hard boundary.
    if (cascadeIdx < cascadeCount - 1)
    {
        float cascadeFar = GetCascadeSplit(splits, cascadeIdx);
        float cascadeNear = (cascadeIdx > 0) ? GetCascadeSplit(splits, cascadeIdx - 1) : 0.0;
        float cascadeRange = cascadeFar - cascadeNear;
        float blendZone = cascadeRange * 0.15;
        float blendStart = cascadeFar - blendZone;

        if (viewDepth > blendStart)
        {
            float blendFactor = saturate((viewDepth - blendStart) / blendZone);
            float secondary = SampleShadowEntry(ShadowData[shadowIndex + cascadeIdx + 1], worldPos, worldNormal, NdotL);
            return lerp(primary, secondary, blendFactor);
        }
    }

    return primary;
}

// Set 2: Material data - matches Materials.CreatePBR() layout
cbuffer MaterialUniforms : register(b0, space2)
{
    float4 BaseColor;       // offset 0
    float Metallic;         // offset 16
    float Roughness;        // offset 20
    float AO;               // offset 24
    float AlphaCutoff;      // offset 28
    float4 EmissiveColor;   // offset 32
};

Texture2D AlbedoMap             : register(t0, space2);
Texture2D NormalMap             : register(t1, space2);
Texture2D MetallicRoughnessMap  : register(t2, space2);
Texture2D OcclusionMap          : register(t3, space2);
Texture2D EmissiveMap           : register(t4, space2);
SamplerState MainSampler        : register(s0, space2);

struct FragmentInput
{
    float4 Position : SV_Position;
    float3 WorldPos : TEXCOORD0;
    float3 WorldNormal : TEXCOORD1;
    float2 TexCoord : TEXCOORD2;
    float4 Color : TEXCOORD3;
    float3 WorldTangent : TEXCOORD4;
    // Current and previous clip-space positions for motion vector computation.
    float4 CurClipPos : TEXCOORD5;
    float4 PrevClipPos : TEXCOORD6;
    bool IsFrontFace : SV_IsFrontFace;
};

/// MRT output: scene color + mini G-buffer (normals + velocity).
struct FragmentOutput
{
    float4 Color     : SV_Target0;  // HDR scene color
    float2 Normal    : SV_Target1;  // view-space normal XY (reconstruct Z)
    float2 Velocity  : SV_Target2;  // screen-space motion vector (UV delta)
};

// ==================== PBR Functions ====================

float DistributionGGX(float NdotH, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float denom = NdotH * NdotH * (a2 - 1.0) + 1.0;
    return a2 / (PI * denom * denom);
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;
    return NdotV / (NdotV * (1.0 - k) + k);
}

float GeometrySmith(float NdotV, float NdotL, float roughness)
{
    return GeometrySchlickGGX(NdotV, roughness) * GeometrySchlickGGX(NdotL, roughness);
}

float3 FresnelSchlick(float cosTheta, float3 F0)
{
    return F0 + (1.0 - F0) * pow(saturate(1.0 - cosTheta), 5.0);
}

// ==================== Light Evaluation ====================

float Attenuation(float distance, float range)
{
    if (range <= 0.0) return 1.0;
    float d = distance / range;
    float d2 = d * d;
    float atten = saturate(1.0 - d2 * d2);
    return atten * atten / (distance * distance + 0.0001);
}

float SpotAttenuation(float3 L, float3 spotDir, float innerCos, float outerCos)
{
    float cosAngle = dot(-L, spotDir);
    return saturate((cosAngle - outerCos) / (innerCos - outerCos + 0.0001));
}

float3 EvaluateLight(GPULight light, float3 worldPos, float3 worldNormal, float viewDepth, float3 N, float3 V, float3 albedo, float roughness, float metallic, float3 F0)
{
    float3 L;
    float atten = 1.0;

    if (light.Type < 0.5) // Directional
    {
        L = normalize(-light.Direction);
    }
    else // Point or Spot
    {
        float3 toLight = light.Position - worldPos;
        float dist = length(toLight);
        L = toLight / dist;
        atten = Attenuation(dist, light.Range);

        if (light.Type > 1.5) // Spot
        {
            atten *= SpotAttenuation(L, normalize(light.Direction), light.InnerConeAngle, light.OuterConeAngle);
        }
    }

    float3 H = normalize(V + L);
    float NdotL = max(dot(N, L), 0.0);
    float NdotH = max(dot(N, H), 0.0);
    float NdotV = max(dot(N, V), 0.001);
    float HdotV = max(dot(H, V), 0.0);

    if (NdotL <= 0.0) return 0.0;

    // Shadow term - geometric NdotL is used for slope-scaled bias to keep
    // shadowing stable across normal mapping.
    float geomNdotL = max(dot(normalize(worldNormal), L), 0.0);
    float shadow = SampleShadow(light, worldPos, worldNormal, geomNdotL, viewDepth);

    float D = DistributionGGX(NdotH, roughness);
    float G = GeometrySmith(NdotV, NdotL, roughness);
    float3 F = FresnelSchlick(HdotV, F0);

    float3 specular = (D * G * F) / (4.0 * NdotV * NdotL + 0.0001);

    float3 kD = (1.0 - F) * (1.0 - metallic);
    float3 diffuse = kD * albedo / PI;

    return (diffuse + specular) * light.Color * NdotL * atten * shadow;
}

// ==================== Normal Mapping ====================

float3 GetNormalFromMap(float3 worldNormal, float3 worldTangent, float2 uv)
{
    float3 tangentNormal = NormalMap.Sample(MainSampler, uv).rgb * 2.0 - 1.0;

    float3 N = normalize(worldNormal);
    float3 T = normalize(worldTangent - dot(worldTangent, N) * N); // re-orthogonalize
    float3 B = cross(N, T);
    float3x3 TBN = float3x3(T, B, N);

    return normalize(mul(tangentNormal, TBN));
}

// ==================== Main ====================

FragmentOutput main(FragmentInput input)
{
    float2 uv = input.TexCoord;

    // Sample textures
    float4 albedoSample = AlbedoMap.Sample(MainSampler, uv);
    float4 mrSample = MetallicRoughnessMap.Sample(MainSampler, uv);
    float aoSample = OcclusionMap.Sample(MainSampler, uv).r;
    float3 emissiveSample = EmissiveMap.Sample(MainSampler, uv).rgb;

    // Combine texture samples with uniform values
    float3 albedo = BaseColor.rgb * albedoSample.rgb * input.Color.rgb;
    float alpha = BaseColor.a * albedoSample.a;
    float roughness = max(Roughness * mrSample.g, 0.04);
    float metallic = Metallic * mrSample.b;
    float ao = AO * aoSample;
    float3 emissive = EmissiveColor.rgb + emissiveSample;

    // Alpha cutoff
    if (alpha < AlphaCutoff)
        discard;

    // Flip geometric normal for back-facing fragments before TBN construction,
    // so normal mapping and lighting are correct for double-sided materials.
    float3 geomNormal = input.WorldNormal;
    float3 geomTangent = input.WorldTangent;
    if (!input.IsFrontFace)
    {
        geomNormal = -geomNormal;
        geomTangent = -geomTangent;
    }

    // Normal - use map if tangent is valid, otherwise geometric normal
    float3 N;
    if (dot(geomTangent, geomTangent) > 0.001)
        N = GetNormalFromMap(geomNormal, geomTangent, uv);
    else
        N = normalize(geomNormal);

    float3 V = normalize(CameraPosition - input.WorldPos);

    // View-space depth (positive distance from camera) for cascade selection.
    float3 viewPos = mul(float4(input.WorldPos, 1.0), ViewMatrix).xyz;
    float viewDepth = -viewPos.z;

    float3 F0 = lerp(0.04, albedo, metallic);

    float3 Lo = 0.0;
    for (uint i = 0; i < LightCount; i++)
    {
        Lo += EvaluateLight(Lights[i], input.WorldPos, geomNormal, viewDepth, N, V, albedo, roughness, metallic, F0);
    }

    float3 ambient = AmbientColor * albedo * ao;
    float3 color = ambient + Lo + emissive;

    // ==================== MRT Output ====================
    FragmentOutput output;

    // Target 1: view-space normal XY. Post-FX reconstruct Z via
    // sqrt(1 - x² - y²). Using the shading normal (N) which includes
    // normal mapping, not the geometric interpolant.
    float3 viewNormal = normalize(mul(float4(N, 0.0), ViewMatrix).xyz);
    output.Normal = viewNormal.xy;

    // Target 0: HDR scene color.
    output.Color = float4(color, alpha);

    // Target 2: screen-space motion vector (NDC delta × 0.5 -> UV delta).
    // Used by TAA / motion blur to reproject from current to previous frame.
    float2 curNDC  = input.CurClipPos.xy / input.CurClipPos.w;
    float2 prevNDC = input.PrevClipPos.xy / input.PrevClipPos.w;
    output.Velocity = (curNDC - prevNDC) * 0.5;

    return output;
}
