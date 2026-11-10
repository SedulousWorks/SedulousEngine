// Sample028_ProceduralRT: RtShader, one of the RHI sample's shaders.
// What Sedulous.Tools.ShaderPack --entries cooks from it, and the sample loads (SampleApp.LoadShader):
// entry: raygen
// model: 6_3

[[vk::image_format("rgba8")]] RWTexture2D<float4> gOutput : register(u0, space0);
RaytracingAccelerationStructure gScene : register(t0, space0);

struct RayPayload
{
    float3 Color;
    float HitT;
    float2 UV;
    float2 _pad;
};

struct SphereAttribs
{
    float3 Normal;
    float HitDist;
};

[shader("raygeneration")]
void RayGen()
{
    uint2 launchIndex = DispatchRaysIndex().xy;
    uint2 launchDim = DispatchRaysDimensions().xy;

    float2 uv = (float2(launchIndex) + 0.5) / float2(launchDim);
    float2 ndc = uv * 2.0 - 1.0;
    ndc.y = -ndc.y;
    float aspect = float(launchDim.x) / float(launchDim.y);
    ndc.x *= aspect;

    RayDesc ray;
    ray.Origin = float3(ndc.x * 2.0, ndc.y * 2.0, -3.0);
    ray.Direction = float3(0.0, 0.0, 1.0);
    ray.TMin = 0.001;
    ray.TMax = 100.0;

    RayPayload payload;
    payload.Color = float3(0.0, 0.0, 0.0);
    payload.HitT = -1.0;
    payload.UV = uv;
    payload._pad = float2(0, 0);

    TraceRay(gScene, RAY_FLAG_FORCE_OPAQUE, 0xFF, 0, 0, 0, ray, payload);

    gOutput[launchIndex] = float4(payload.Color, 1.0);
}

[shader("intersection")]
void SphereIntersection()
{
    // AABB center is at origin of the geometry instance, radius 0.5
    float3 center = float3(0, 0, 0);
    float radius = 0.45;

    float3 origin = ObjectRayOrigin();
    float3 dir = ObjectRayDirection();
    float3 oc = origin - center;

    float a = dot(dir, dir);
    float b = 2.0 * dot(oc, dir);
    float c = dot(oc, oc) - radius * radius;
    float discriminant = b * b - 4.0 * a * c;

    if (discriminant >= 0.0)
    {
        float t = (-b - sqrt(discriminant)) / (2.0 * a);
        if (t >= RayTMin() && t <= RayTCurrent())
        {
            float3 hitPos = origin + t * dir;
            float3 normal = normalize(hitPos - center);

            SphereAttribs attribs;
            attribs.Normal = normal;
            attribs.HitDist = t;
            ReportHit(t, 0, attribs);
        }
    }
}

[shader("closesthit")]
void ClosestHit(inout RayPayload payload, SphereAttribs attribs)
{
    // Simple diffuse shading
    float3 lightDir = normalize(float3(0.5, 1.0, -0.5));
    float3 normal = normalize(mul((float3x3)ObjectToWorld3x4(), attribs.Normal));
    float ndotl = max(0.0, dot(normal, lightDir));
    float ambient = 0.15;

    // Color based on instance index
    uint instID = InstanceIndex();
    float3 baseColor;
    if (instID == 0) baseColor = float3(1.0, 0.3, 0.3);
    else if (instID == 1) baseColor = float3(0.3, 1.0, 0.3);
    else if (instID == 2) baseColor = float3(0.3, 0.3, 1.0);
    else baseColor = float3(1.0, 1.0, 0.3);

    payload.Color = baseColor * (ndotl + ambient);
    payload.HitT = attribs.HitDist;
}

[shader("miss")]
void Miss(inout RayPayload payload)
{
    payload.Color = float3(0.05, 0.05, 0.1) + float3(0.0, 0.0, 0.15) * payload.UV.y;
    payload.HitT = -1.0;
}
