namespace Sedulous.ShaderReflection.Tests;

using System;
using Sedulous.RHI;

/// Phase 4: DXIL reflection — resource binding tests.
class DXILBindingTests
{
	[Test]
	public static void TestVertexShaderBindings()
	{
		let bytecode = TestHelper.LoadShader("test_bindings_vs.dxil");
		Test.Assert(bytecode != null, "Failed to load test_bindings_vs.dxil");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.DXIL, bytecode, "VSMain");
		Test.Assert(result case .Ok(let shader), "DXIL vertex shader reflection failed");
		defer delete shader;

		Test.Assert(shader.Stage == .Vertex, "Stage should be Vertex");

		// VS only uses: SceneConstants (b0,s0), ModelConstants (b1,s0), BoneBuffer (t1,s1)
		// DiffuseMap and LinearSampler are optimized out (only used in PS)
		Test.Assert(shader.Bindings.Count >= 3, scope String()..AppendF("Expected >= 3 bindings, got {}", shader.Bindings.Count));

		let scene = TestHelper.FindBinding(shader, "SceneConstants");
		if (scene != null)
		{
			Test.Assert(scene.Value.Type == .UniformBuffer, "SceneConstants should be UniformBuffer");
			Test.Assert(scene.Value.Set == 0, "SceneConstants should be in set 0");
			Test.Assert(scene.Value.Binding == 0, "SceneConstants should be at binding 0");
		}

		let model = TestHelper.FindBinding(shader, "ModelConstants");
		if (model != null)
		{
			Test.Assert(model.Value.Type == .UniformBuffer, "ModelConstants should be UniformBuffer");
			Test.Assert(model.Value.Set == 0, "ModelConstants should be in set 0");
			Test.Assert(model.Value.Binding == 1, "ModelConstants should be at binding 1");
		}

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
		let bytecode = TestHelper.LoadShader("test_bindings_ps.dxil");
		Test.Assert(bytecode != null, "Failed to load test_bindings_ps.dxil");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.DXIL, bytecode, "PSMain");
		Test.Assert(result case .Ok(let shader), "DXIL pixel shader reflection failed");
		defer delete shader;

		Test.Assert(shader.Stage == .Fragment, "Stage should be Fragment (pixel)");
		Test.Assert(shader.Bindings.Count >= 2, scope String()..AppendF("Expected >= 2 bindings, got {}", shader.Bindings.Count));
	}

	[Test]
	public static void TestBindingCount()
	{
		let bytecode = TestHelper.LoadShader("test_bindings_vs.dxil");
		Test.Assert(bytecode != null, "Failed to load test_bindings_vs.dxil");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.DXIL, bytecode);
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		for (let b in shader.Bindings)
			Test.Assert(b.Count == 1, scope String()..AppendF("Binding '{}' should have Count=1, got {}", b.Name, b.Count));
	}

	[Test]
	public static void TestStageFlags()
	{
		let bytecode = TestHelper.LoadShader("test_bindings_vs.dxil");
		Test.Assert(bytecode != null, "Failed to load test_bindings_vs.dxil");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.DXIL, bytecode);
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		for (let b in shader.Bindings)
			Test.Assert(b.Stages == .Vertex, scope String()..AppendF("Binding '{}' stages should be Vertex", b.Name));
	}
}
