// Sky Fragment Shader - equirectangular HDR sky or procedural gradient fallback
// Samples an equirectangular environment map using the view direction.

cbuffer LightParams : register(b1, space0)
{
    uint LightCount;
    float3 AmbientColor;
};

struct GPULight
{
    float3 Position;
    float Type;
    float3 Direction;
    float Range;
    float3 Color;
    float Intensity;
    float InnerConeAngle;
    float OuterConeAngle;
    float ShadowBias;
    float _Pad;
};

StructuredBuffer<GPULight> Lights : register(t0, space0);

// Sky bind group (set 1)
cbuffer SkyParams : register(b0, space1)
{
    float SkyIntensity;
    float HasEnvironmentMap;
    float2 _SkyPad;
};

Texture2D EnvironmentMap : register(t0, space1);
SamplerState SkySampler : register(s0, space1);

struct FragmentInput
{
    float4 Position : SV_Position;
    float3 ViewDir : TEXCOORD0;
};

// Convert direction to equirectangular UV
float2 DirectionToEquirectangular(float3 dir)
{
    float phi = atan2(dir.z, dir.x);   // [-PI, PI]
    float theta = asin(dir.y);          // [-PI/2, PI/2]

    float u = phi / (2.0 * 3.14159265) + 0.5;
    float v = theta / 3.14159265 + 0.5;

    return float2(u, 1.0 - v);
}

float3 ProceduralSky(float3 dir)
{
    float3 horizonColor = float3(0.6, 0.7, 0.85);
    float3 zenithColor = float3(0.15, 0.3, 0.65);
    float3 groundColor = float3(0.3, 0.28, 0.25);

    float3 sky;
    if (dir.y >= 0)
    {
        float skyT = pow(saturate(dir.y), 0.5);
        sky = lerp(horizonColor, zenithColor, skyT);
    }
    else
    {
        float groundT = pow(saturate(-dir.y), 0.8);
        sky = lerp(horizonColor, groundColor, groundT);
    }

    // Sun disc from first directional light
    for (uint i = 0; i < LightCount; i++)
    {
        if (Lights[i].Type < 0.5)
        {
            float3 sunDir = normalize(-Lights[i].Direction);
            float sunDot = dot(dir, sunDir);

            float sunSize = 0.9995;
            if (sunDot > sunSize)
            {
                float sunFade = saturate((sunDot - sunSize) / (1.0 - sunSize));
                sky = lerp(sky, Lights[i].Color * 2.0, sunFade);
            }

            float glowFade = pow(saturate(sunDot), 64.0);
            sky += Lights[i].Color * glowFade * 0.3;
            break;
        }
    }

    return sky;
}

float4 main(FragmentInput input) : SV_Target
{
    float3 dir = normalize(input.ViewDir);

    float3 sky;
    if (HasEnvironmentMap > 0.5)
    {
        float2 uv = DirectionToEquirectangular(dir);
        sky = EnvironmentMap.Sample(SkySampler, uv).rgb * SkyIntensity;
    }
    else
    {
        sky = ProceduralSky(dir);
    }

    return float4(sky, 1.0);
}
