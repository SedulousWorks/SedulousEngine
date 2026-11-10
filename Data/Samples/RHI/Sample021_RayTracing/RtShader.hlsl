// Sample021_RayTracing: RtShader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: raygen
// model: 6_3

[[vk::image_format("rgba8")]] RWTexture2D<float4> gOutput : register(u0, space0);
RaytracingAccelerationStructure gScene : register(t0, space0);

struct RayPayload
{
    float3 Color;
};

[shader("raygeneration")]
void RayGen()
{
    uint2 launchIndex = DispatchRaysIndex().xy;
    uint2 launchDim = DispatchRaysDimensions().xy;

    float2 uv = (float2(launchIndex) + 0.5) / float2(launchDim);
    float2 ndc = uv * 2.0 - 1.0;
    ndc.y = -ndc.y;

    RayDesc ray;
    ray.Origin = float3(ndc.x, ndc.y, -1.0);
    ray.Direction = float3(0.0, 0.0, 1.0);
    ray.TMin = 0.001;
    ray.TMax = 100.0;

    RayPayload payload;
    payload.Color = float3(0.0, 0.0, 0.0);

    TraceRay(gScene, RAY_FLAG_FORCE_OPAQUE, 0xFF, 0, 0, 0, ray, payload);

    gOutput[launchIndex] = float4(payload.Color, 1.0);
}

[shader("closesthit")]
void ClosestHit(inout RayPayload payload, BuiltInTriangleIntersectionAttributes attribs)
{
    float3 bary = float3(1.0 - attribs.barycentrics.x - attribs.barycentrics.y,
                         attribs.barycentrics.x,
                         attribs.barycentrics.y);

    payload.Color = float3(bary.x, bary.y, bary.z);
}

[shader("miss")]
void Miss(inout RayPayload payload)
{
    float2 uv = (float2(DispatchRaysIndex().xy) + 0.5) / float2(DispatchRaysDimensions().xy);
    payload.Color = float3(0.1, 0.1, 0.2) + float3(0.0, 0.0, 0.3) * uv.y;
}
