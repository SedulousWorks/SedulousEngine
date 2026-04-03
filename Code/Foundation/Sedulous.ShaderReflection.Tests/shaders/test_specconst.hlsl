// Test shader with specialization constants (Vulkan only).
//
// Compile (SPIR-V only — DXIL has no specialization constants):
//   dxc -T cs_6_0 -E CSMain -spirv -Fo test_specconst.spv test_specconst.hlsl

[[vk::constant_id(0)]] const bool ENABLE_FEATURE = true;
[[vk::constant_id(1)]] const int MODE = 2;
[[vk::constant_id(2)]] const uint TILE_SIZE = 16;
[[vk::constant_id(3)]] const float SCALE = 1.5;

RWStructuredBuffer<float4> Output : register(u0, space0);

[numthreads(64, 1, 1)]
void CSMain(uint3 tid : SV_DispatchThreadID)
{
    float4 result = float4(0, 0, 0, 0);

    if (ENABLE_FEATURE)
        result.x = float(MODE) * SCALE;

    result.y = float(TILE_SIZE);

    Output[tid.x] = result;
}
