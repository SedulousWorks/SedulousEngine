// Particle fragment shader — samples texture, multiplies by vertex color,
// and applies soft-particle depth fade at geometry intersections.
//
// The ParticlePass declares both ReadDepth and ReadTexture on SceneDepth,
// so the depth buffer is in DEPTH_STENCIL_READ_ONLY_OPTIMAL layout —
// allowing simultaneous depth testing and shader sampling.

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

/// Linearizes a depth buffer value to view-space distance.
float LinearizeDepth(float d)
{
    return NearPlane * FarPlane / (FarPlane - d * (FarPlane - NearPlane));
}

float4 main(FragmentInput input) : SV_Target
{
    float4 texSample = ParticleTexture.Sample(ParticleSampler, input.TexCoord);
    float4 result = texSample * input.Color;

    // Discard fully transparent fragments.
    clip(result.a - 0.001);

    // Soft particle fade: compare particle depth with scene depth.
    // Fade alpha when the particle is close to opaque geometry.
    float2 screenUV = input.Position.xy * InvScreenSize;
    float sceneDepthRaw = SceneDepth.Sample(DepthSampler, screenUV).r;
    float sceneLinear = LinearizeDepth(sceneDepthRaw);
    float particleLinear = LinearizeDepth(input.Position.z);

    float softness = 0.5; // fade distance in world units
    float depthDiff = sceneLinear - particleLinear;
    float softFade = saturate(depthDiff / softness);
    result.a *= softFade;

    return result;
}
