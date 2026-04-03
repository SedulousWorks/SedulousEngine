// Test compute shader with thread group size and storage buffer bindings.
//
// Compile:
//   dxc -T cs_6_0 -E CSMain -Fo test_compute.dxil test_compute.hlsl
//   dxc -T cs_6_0 -E CSMain -spirv -Fo test_compute.spv test_compute.hlsl

cbuffer Params : register(b0, space0)
{
    uint Count;
    float Scale;
};

StructuredBuffer<float4>   InputBuffer  : register(t0, space0);
RWStructuredBuffer<float4> OutputBuffer : register(u0, space0);

[numthreads(64, 1, 1)]
void CSMain(uint3 id : SV_DispatchThreadID)
{
    if (id.x < Count)
        OutputBuffer[id.x] = InputBuffer[id.x] * Scale;
}
