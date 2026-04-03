namespace Sedulous.ShaderReflection.Tests;

using System;
using Sedulous.RHI;

/// Phase 2: SPIR-V reflection — resource binding tests.
class SPIRVBindingTests
{
	[Test]
	public static void TestVertexShaderBindings()
	{
		let bytecode = TestHelper.LoadShader("test_bindings_vs.spv");
		Test.Assert(bytecode != null, "Failed to load test_bindings_vs.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode, "VSMain");
		Test.Assert(result case .Ok(let shader), "SPIR-V vertex shader reflection failed");
		defer delete shader;

		Test.Assert(shader.Stage == .Vertex, "Stage should be Vertex");

		// VS only uses: SceneConstants (b0,s0), ModelConstants (b1,s0), BoneBuffer (t1,s1)
		// DiffuseMap and LinearSampler are optimized out (only used in PS)
		Test.Assert(shader.Bindings.Count >= 3, scope String()..AppendF("Expected >= 3 bindings, got {}", shader.Bindings.Count));

		// Check uniform buffers
		let scene = TestHelper.FindBinding(shader, "SceneConstants");
		if (scene != null)
		{
			Test.Assert(scene.Value.Type == .UniformBuffer, "SceneConstants should be UniformBuffer");
			Test.Assert(scene.Value.Set == 0, "SceneConstants should be in set 0");
		}

		let model = TestHelper.FindBinding(shader, "ModelConstants");
		if (model != null)
		{
			Test.Assert(model.Value.Type == .UniformBuffer, "ModelConstants should be UniformBuffer");
			Test.Assert(model.Value.Set == 0, "ModelConstants should be in set 0");
		}

		// Check read-only storage buffer (StructuredBuffer)
		let bones = TestHelper.FindBinding(shader, "BoneBuffer");
		if (bones != null)
		{
			Test.Assert(bones.Value.Type == .StorageBufferReadOnly, "BoneBuffer should be StorageBufferReadOnly");
			Test.Assert(bones.Value.Set == 1, "BoneBuffer should be in set 1");
		}
	}

	[Test]
	public static void TestPixelShaderBindings()
	{
		let bytecode = TestHelper.LoadShader("test_bindings_ps.spv");
		Test.Assert(bytecode != null, "Failed to load test_bindings_ps.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode, "PSMain");
		Test.Assert(result case .Ok(let shader), "SPIR-V pixel shader reflection failed");
		defer delete shader;

		Test.Assert(shader.Stage == .Fragment, "Stage should be Fragment");

		// PS uses DiffuseMap and LinearSampler
		Test.Assert(shader.Bindings.Count >= 2, scope String()..AppendF("Expected >= 2 bindings, got {}", shader.Bindings.Count));
	}

	[Test]
	public static void TestBindingCount()
	{
		let bytecode = TestHelper.LoadShader("test_bindings_vs.spv");
		Test.Assert(bytecode != null, "Failed to load test_bindings_vs.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode);
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		// All non-array bindings should have Count == 1
		for (let b in shader.Bindings)
			Test.Assert(b.Count == 1, scope String()..AppendF("Binding '{}' should have Count=1, got {}", b.Name, b.Count));
	}

	[Test]
	public static void TestStageFlags()
	{
		let bytecode = TestHelper.LoadShader("test_bindings_vs.spv");
		Test.Assert(bytecode != null, "Failed to load test_bindings_vs.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode);
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		// All bindings from a vertex shader should have Vertex stage
		for (let b in shader.Bindings)
			Test.Assert(b.Stages == .Vertex, scope String()..AppendF("Binding '{}' stages should be Vertex", b.Name));
	}
}
