// Screen-Space Reflections Fragment Shader
// Ray marches in view space, projects each sample to screen space for depth lookup.
// Outputs RGBA16Float: rgb = reflection color, a = confidence.

#pragma pack_matrix(row_major)

cbuffer SSRParams : register(b0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
    float4x4 InvProjectionMatrix;
    float4x4 InvViewProjectionMatrix;
    float2 ScreenSize;
    float2 InvScreenSize;
    float NearPlane;
    float FarPlane;
    float MaxDistance;
    float Thickness;
    int MaxSteps;
    int BinarySteps;
    float2 _Pad;
};

Texture2D SceneColor   : register(t0);
Texture2D SceneDepth   : register(t1);
Texture2D SceneNormals : register(t2);
SamplerState PointSampler  : register(s0);
SamplerState LinearSampler : register(s1);

// Reconstruct view-space position from UV + raw depth
float3 ReconstructViewPos(float2 uv, float depth)
{
    float2 ndc = uv * 2.0 - 1.0;
    ndc.y = -ndc.y;
    float4 clipPos = float4(ndc, depth, 1.0);
    float4 viewPos = mul(clipPos, InvProjectionMatrix);
    return viewPos.xyz / viewPos.w;
}

// Project view-space position to screen UV
float2 ProjectToUV(float3 viewPos)
{
    float4 clipPos = mul(float4(viewPos, 1.0), ProjectionMatrix);
    clipPos.xy /= clipPos.w;
    float2 uv = clipPos.xy * 0.5 + 0.5;
    uv.y = 1.0 - uv.y;
    return uv;
}

// Edge fade near screen borders
float ScreenEdgeFade(float2 uv)
{
    float2 fade = smoothstep(0.0, 0.1, uv) * (1.0 - smoothstep(0.9, 1.0, uv));
    return fade.x * fade.y;
}

struct PSInput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
};

float4 main(PSInput input) : SV_Target0
{
    float2 uv = input.TexCoord;

    // Sample depth and reconstruct view-space position
    float depth = SceneDepth.SampleLevel(PointSampler, uv, 0).r;
    if (depth >= 1.0)
        return float4(0, 0, 0, 0);

    float3 viewPos = ReconstructViewPos(uv, depth);

    // Reconstruct view-space normal and read roughness/metallic
    float4 normalData = SceneNormals.SampleLevel(PointSampler, uv, 0);
    float2 normalXY = normalData.rg;
    float roughness = normalData.b;
    float metallic = normalData.a;
    float3 viewNormal = normalize(float3(normalXY, sqrt(max(0.0, 1.0 - dot(normalXY, normalXY)))));

    // Reflectivity based on roughness: smooth surfaces reflect strongly,
    // rough surfaces not at all. Use a steep power curve so only very
    // smooth surfaces (roughness < ~0.3) get noticeable SSR.
    float reflectivity = pow(max(0.0, 1.0 - roughness), 4.0);
    if (reflectivity < 0.01)
        return float4(0, 0, 0, 0);

    // Reflection direction in view space
    float3 viewDir = normalize(viewPos);
    float3 reflectDir = reflect(viewDir, viewNormal);

    // Step size in view space
    float stepLen = MaxDistance / (float)MaxSteps;
    float3 rayStep = reflectDir * stepLen;

    // Jitter start position to reduce banding (screen-space noise)
    float jitter = frac(sin(dot(input.Position.xy, float2(12.9898, 78.233))) * 43758.5453);

    // March in view space, project each sample to get UV for depth lookup
    float3 rayPos = viewPos + rayStep * (1.0 + jitter * 0.5); // jittered start
    bool hit = false;

    for (int i = 0; i < MaxSteps; i++)
    {
        float2 sampleUV = ProjectToUV(rayPos);

        // Out of screen bounds
        if (sampleUV.x < 0 || sampleUV.x > 1 || sampleUV.y < 0 || sampleUV.y > 1)
            break;

        // Sample scene depth at projected position and reconstruct its view-space position
        float sampledDepth = SceneDepth.SampleLevel(PointSampler, sampleUV, 0).r;
        float3 sceneViewPos = ReconstructViewPos(sampleUV, sampledDepth);

        // Compare in view space Z (both negative, camera at origin looking down -Z)
        float depthDiff = sceneViewPos.z - rayPos.z;

        // Hit: ray is behind the surface (depthDiff > 0) but not too far behind
        if (depthDiff > 0.0 && depthDiff < Thickness)
        {
            hit = true;
            break;
        }

        rayPos += rayStep;
    }

    if (!hit)
        return float4(0, 0, 0, 0);

    // Binary refinement in view space
    float3 backStep = rayStep * 0.5;
    for (int i = 0; i < BinarySteps; i++)
    {
        rayPos -= backStep;
        backStep *= 0.5;

        float2 sampleUV = ProjectToUV(rayPos);
        float sampledDepth = SceneDepth.SampleLevel(PointSampler, sampleUV, 0).r;
        float3 sceneViewPos = ReconstructViewPos(sampleUV, sampledDepth);

        if (sceneViewPos.z > rayPos.z)
            rayPos -= backStep;
        else
            rayPos += backStep;
    }

    // Sample reflection color
    float2 hitUV = saturate(ProjectToUV(rayPos));
    float3 reflectionColor = SceneColor.SampleLevel(LinearSampler, hitUV, 0).rgb;

    // Confidence: combine screen edge fade, distance fade, and surface reflectivity
    float confidence = ScreenEdgeFade(hitUV);

    // Fade by march distance
    float marchDist = length(rayPos - viewPos);
    confidence *= 1.0 - saturate(marchDist / MaxDistance);

    // Scale by surface reflectivity (smooth = strong, rough = none)
    confidence *= reflectivity;

    return float4(reflectionColor, confidence);
}
