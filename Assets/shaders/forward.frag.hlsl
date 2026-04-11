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

// Samples a shadow map and returns the lit fraction (1 = lit, 0 = shadowed).
//
// Matches the legacy Sedulous renderer:
//   - Receiver lookup with normal-offset bias scaled by world-space cascade texel size
//   - Cascade selection by view-space depth (directional only)
//   - saturate(z) instead of rejection (avoids popping at cascade far)
//   - Plain 5×5 box PCF (hardware depth bias prevents acne, not the shader)
float SampleShadow(int shadowIndex, float3 worldPos, float3 worldNormal, float NdotL, float viewDepth)
{
    if (shadowIndex < 0) return 1.0;

    GPUShadowData shadow = ShadowData[shadowIndex];

    // Cascade selection for directional lights — done BEFORE normal offset so we
    // use the right cascade's world texel size.
    if (shadow.CascadeCount > 0)
    {
        int cascadeIdx = shadow.CascadeCount - 1;
        if (viewDepth < shadow.CascadeSplits.x)      cascadeIdx = 0;
        else if (viewDepth < shadow.CascadeSplits.y) cascadeIdx = 1;
        else if (viewDepth < shadow.CascadeSplits.z) cascadeIdx = 2;
        else if (viewDepth < shadow.CascadeSplits.w) cascadeIdx = 3;

        shadow = ShadowData[shadowIndex + cascadeIdx];
    }

    // Normal-offset bias in world space: NormalBias is in texels, scale by the
    // cascade's world texel size, and fade at grazing angles (NdotL → 0).
    float3 biasedPos = worldPos + worldNormal * (shadow.NormalBias * shadow.WorldTexelSize * (1.0 - NdotL));

    float4 lightClip = mul(float4(biasedPos, 1.0), shadow.LightViewProj);
    if (lightClip.w <= 0.0) return 1.0;

    float3 lightNDC = lightClip.xyz / lightClip.w;

    // NDC → shadow map UV (DX-style: y inverted). saturate lets fragments just past
    // the far plane still sample (clamped) rather than popping to fully-lit.
    float2 shadowUV = float2(lightNDC.x * 0.5 + 0.5, -lightNDC.y * 0.5 + 0.5);
    if (any(shadowUV < 0.0) || any(shadowUV > 1.0))
        return 1.0;
    float compareDepth = saturate(lightNDC.z) - shadow.Bias;

    // Local UV → atlas UV.
    float2 atlasUV = shadow.AtlasUVRect.xy + shadowUV * shadow.AtlasUVRect.zw;

    // Plain 5×5 box PCF. 25 hardware comparison taps → 100 effective bilinear
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

// Set 2: Material data — matches Materials.CreatePBR() layout
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

    // Shadow term — geometric NdotL is used for slope-scaled bias to keep
    // shadowing stable across normal mapping.
    float geomNdotL = max(dot(normalize(worldNormal), L), 0.0);
    float shadow = SampleShadow(light.ShadowIndex, worldPos, worldNormal, geomNdotL, viewDepth);

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

float4 main(FragmentInput input) : SV_Target
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

    // Normal — use map if tangent is valid, otherwise geometric normal
    float3 N;
    if (dot(input.WorldTangent, input.WorldTangent) > 0.001)
        N = GetNormalFromMap(input.WorldNormal, input.WorldTangent, uv);
    else
        N = normalize(input.WorldNormal);

    float3 V = normalize(CameraPosition - input.WorldPos);

    // View-space depth (positive distance from camera) for cascade selection.
    float3 viewPos = mul(float4(input.WorldPos, 1.0), ViewMatrix).xyz;
    float viewDepth = -viewPos.z;

    float3 F0 = lerp(0.04, albedo, metallic);

    float3 Lo = 0.0;
    for (uint i = 0; i < LightCount; i++)
    {
        Lo += EvaluateLight(Lights[i], input.WorldPos, input.WorldNormal, viewDepth, N, V, albedo, roughness, metallic, F0);
    }

    float3 ambient = AmbientColor * albedo * ao;
    float3 color = ambient + Lo + emissive;

    return float4(color, alpha);
}
