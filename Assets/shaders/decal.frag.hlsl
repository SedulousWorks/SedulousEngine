// Decal fragment shader.
//
// Reads the scene depth buffer at the fragment's screen position, reconstructs
// the world-space position of the actual scene surface, transforms it into
// decal local space, clips if outside the [-0.5, 0.5] volume, and samples the
// decal texture at the local XY coordinate. Optional angle-fade attenuates
// fragments whose receiving surface faces away from the decal.

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

cbuffer DecalUniforms : register(b0, space3)
{
    float4x4 DecalWorld;
    float4x4 DecalInvWorld;
    float4   DecalColor;
    float    AngleFadeStart;
    float    AngleFadeEnd;
    float2   _DecalPad;
};

// Set 1 - render-pass inputs: scene depth + point sampler.
Texture2D    SceneDepth : register(t0, space1);
SamplerState DepthSampler : register(s0, space1);

// Set 2 - decal material (texture + sampler).
Texture2D    DecalTexture : register(t0, space2);
SamplerState DecalSampler : register(s0, space2);

struct FragmentInput
{
    float4 Position : SV_Position;
    float2 ScreenUV : TEXCOORD0;
};

float4 main(FragmentInput input) : SV_Target
{
    // Reconstruct world-space position of the scene surface at this pixel.
    float2 screenUV = input.Position.xy * InvScreenSize;
    float depth = SceneDepth.Sample(DepthSampler, screenUV).r;

    // Screen UV → NDC. Y flipped: top-left origin for UV, top-right is (+1,+1) in NDC.
    float2 ndcXY = float2(screenUV.x * 2.0 - 1.0, 1.0 - screenUV.y * 2.0);
    float4 ndcPos = float4(ndcXY, depth, 1.0);
    float4 worldPos4 = mul(ndcPos, InvViewProjectionMatrix);
    float3 worldPos = worldPos4.xyz / worldPos4.w;

    // World → decal local (centered at origin, extents [-0.5, 0.5]).
    float4 localPos4 = mul(float4(worldPos, 1.0), DecalInvWorld);
    float3 local = localPos4.xyz;
    if (any(abs(local) > 0.5))
        discard;

    // Receiver normal derived from depth derivatives (cheap, works without a G-buffer).
    float3 dpdx = ddx(worldPos);
    float3 dpdy = ddy(worldPos);
    float3 receiverNormal = normalize(cross(dpdy, dpdx));

    // Decal forward vector = world-space +Z axis of the decal transform (the
    // direction the projector "shines" toward).
    float3 decalForward = normalize(float3(DecalWorld._m20, DecalWorld._m21, DecalWorld._m22));

    // Angle fade: fully opaque when the receiver normal faces directly at the
    // decal source (-decalForward). Fades out as the surface becomes parallel
    // to the projection direction.
    float cosAngle = dot(receiverNormal, -decalForward);
    float angleFade = smoothstep(cos(AngleFadeEnd), cos(AngleFadeStart), cosAngle);

    // Sample the decal texture using local-space XY mapped to [0,1].
    float2 uv = local.xy + 0.5;
    // Flip V for texture-space convention (top-down).
    uv.y = 1.0 - uv.y;
    float4 sample = DecalTexture.Sample(DecalSampler, uv);

    float4 result = sample * DecalColor;
    result.a *= angleFade;
    return result;
}
