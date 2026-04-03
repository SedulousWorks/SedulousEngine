// Test ray generation shader.
//
// Compile:
//   dxc -T lib_6_3 -Fo test_raygen.dxil test_raygen.hlsl
//   dxc -T lib_6_3 -spirv -Fo test_raygen.spv test_raygen.hlsl

RaytracingAccelerationStructure Scene : register(t0, space0);
RWTexture2D<float4> Output           : register(u0, space0);

cbuffer RayParams : register(b0, space0)
{
    float4x4 InvViewProjection;
    float4   CameraPos;
};

struct RayPayload
{
    float4 Color;
};

[shader("raygeneration")]
void RayGen()
{
    uint2 launchIndex = DispatchRaysIndex().xy;
    uint2 launchDim = DispatchRaysDimensions().xy;

    float2 uv = float2(launchIndex) / float2(launchDim);

    RayDesc ray;
    ray.Origin = CameraPos.xyz;
    ray.Direction = normalize(float3(uv * 2.0 - 1.0, 1.0));
    ray.TMin = 0.001;
    ray.TMax = 1000.0;

    RayPayload payload;
    payload.Color = float4(0, 0, 0, 1);
    TraceRay(Scene, RAY_FLAG_NONE, 0xFF, 0, 0, 0, ray, payload);

    Output[launchIndex] = payload.Color;
}
