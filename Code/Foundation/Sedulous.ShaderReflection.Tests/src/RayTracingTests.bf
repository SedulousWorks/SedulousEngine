namespace Sedulous.ShaderReflection.Tests;

using System;
using Sedulous.RHI;

/// Phase 8: Ray tracing shader reflection tests.
class RayTracingTests
{
	[Test]
	public static void TestSPIRVRayGenStage()
	{
		let bytecode = TestHelper.LoadShader("test_raygen.spv");
		Test.Assert(bytecode != null, "Failed to load test_raygen.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode, "RayGen");
		Test.Assert(result case .Ok(let shader), "SPIR-V raygen shader reflection failed");
		defer delete shader;

		Test.Assert(shader.Stage == .RayGen, scope String()..AppendF("Stage should be RayGen, got {}", shader.Stage));
	}

	[Test]
	public static void TestSPIRVRayGenBindings()
	{
		let bytecode = TestHelper.LoadShader("test_raygen.spv");
		Test.Assert(bytecode != null, "Failed to load test_raygen.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode);
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		// RayGen has: Scene (AccelerationStructure t0,s0), Output (RW Texture u0,s0), RayParams (UB b0,s0)
		Test.Assert(shader.Bindings.Count >= 3,
			scope String()..AppendF("Expected >= 3 bindings, got {}", shader.Bindings.Count));

		let scene = TestHelper.FindBinding(shader, "Scene");
		Test.Assert(scene != null, "Should have Scene binding");
		if (scene != null)
		{
			Test.Assert(scene.Value.Type == .AccelerationStructure,
				scope String()..AppendF("Scene should be AccelerationStructure, got {}", scene.Value.Type));
			Test.Assert(scene.Value.Stages == .RayGen, "Scene stages should be RayGen");
		}

		let output = TestHelper.FindBinding(shader, "Output");
		Test.Assert(output != null, "Should have Output binding");
		if (output != null)
			Test.Assert(output.Value.Type == .StorageTextureReadWrite,
				scope String()..AppendF("Output should be StorageTextureReadWrite, got {}", output.Value.Type));

		let rayParams = TestHelper.FindBinding(shader, "type.RayParams");
		Test.Assert(rayParams != null, "Should have RayParams binding");
		if (rayParams != null)
			Test.Assert(rayParams.Value.Type == .UniformBuffer, "RayParams should be UniformBuffer");
	}

	[Test]
	public static void TestSPIRVRayGenNoThreadGroupSize()
	{
		let bytecode = TestHelper.LoadShader("test_raygen.spv");
		Test.Assert(bytecode != null, "Failed to load test_raygen.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode);
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		// Ray gen shaders don't have thread group size
		Test.Assert(shader.ThreadGroupSize[0] == 0, "RayGen should have ThreadGroupSize.x == 0");
		Test.Assert(shader.ThreadGroupSize[1] == 0, "RayGen should have ThreadGroupSize.y == 0");
		Test.Assert(shader.ThreadGroupSize[2] == 0, "RayGen should have ThreadGroupSize.z == 0");
	}
}
