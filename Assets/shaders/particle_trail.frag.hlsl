// Particle trail fragment shader — texture × vertex color with soft-particle depth fade.

#pragma pack_matrix(row_major)

cbuffer SceneUniforms : register(b0, space0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
    float4x4 ViewProjectionMatrix;
    float4x4 InvViewMatrix;
    float4x4 InvProjectionMatrix;
    float4x4 InvViewProjectionMatrix;
    float4x4 PrevViewProjectionMatrix;
    float3   CameraPosition;
    float    NearPlane;
    float    FarPlane;
    float    Time;
    float    DeltaTime;
    float    _Pad0;
    float2   ScreenSize;
    float2   InvScreenSize;
};

// Set 1 — scene depth for soft particles.
Texture2D    SceneDepth    : register(t0, space1);
SamplerState DepthSampler  : register(s0, space1);

// Set 2 — particle material (texture + sampler).
Texture2D    ParticleTexture : register(t0, space2);
SamplerState ParticleSampler : register(s0, space2);

struct FragmentInput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
    float4 Color    : COLOR0;
};

float LinearizeDepth(float d)
{
    return NearPlane * FarPlane / (FarPlane - d * (FarPlane - NearPlane));
}

float4 main(FragmentInput input) : SV_Target
{
    float4 texSample = ParticleTexture.Sample(ParticleSampler, input.TexCoord);
    float4 result = texSample * input.Color;
    clip(result.a - 0.001);

    // Soft particle fade
    float2 screenUV = input.Position.xy * InvScreenSize;
    float sceneDepthRaw = SceneDepth.Sample(DepthSampler, screenUV).r;
    float sceneLinear = LinearizeDepth(sceneDepthRaw);
    float particleLinear = LinearizeDepth(input.Position.z);

    float softness = 0.3;
    float depthDiff = sceneLinear - particleLinear;
    float softFade = saturate(depthDiff / softness);
    result.a *= softFade;

    return result;
}
