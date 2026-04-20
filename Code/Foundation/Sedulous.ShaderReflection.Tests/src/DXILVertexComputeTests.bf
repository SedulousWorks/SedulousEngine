namespace Sedulous.ShaderReflection.Tests;

using System;
using Sedulous.RHI;

/// Phase 5: DXIL reflection - vertex inputs and compute thread group size.
class DXILVertexComputeTests
{
	[Test]
	public static void TestTriangleVertexInputs()
	{
		let bytecode = TestHelper.LoadShader("triangle_vs.dxil");
		Test.Assert(bytecode != null, "Failed to load triangle_vs.dxil");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.DXIL, bytecode, "VSMain");
		Test.Assert(result case .Ok(let shader), "DXIL triangle VS reflection failed");
		defer delete shader;

		Test.Assert(shader.Stage == .Vertex, "Stage should be Vertex");
		// Triangle has: TEXCOORD0 (float3, index 0), TEXCOORD1 (float3, index 1)
		Test.Assert(shader.VertexInputs.Count == 2, scope String()..AppendF("Expected 2 vertex inputs, got {}", shader.VertexInputs.Count));

		let pos = TestHelper.FindVertexInputByLocation(shader, 0);
		Test.Assert(pos != null, "Should have vertex input at location 0 (TEXCOORD0)");
		if (pos != null)
			Test.Assert(pos.Value.Format == .Float32x3, scope String()..AppendF("Position should be Float32x3, got {}", pos.Value.Format));

		let color = TestHelper.FindVertexInputByLocation(shader, 1);
		Test.Assert(color != null, "Should have vertex input at location 1 (TEXCOORD1)");
		if (color != null)
			Test.Assert(color.Value.Format == .Float32x3, scope String()..AppendF("Color should be Float32x3, got {}", color.Value.Format));
	}

	[Test]
	public static void TestBindingsVertexInputs()
	{
		let bytecode = TestHelper.LoadShader("test_bindings_vs.dxil");
		Test.Assert(bytecode != null, "Failed to load test_bindings_vs.dxil");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.DXIL, bytecode, "VSMain");
		Test.Assert(result case .Ok(let shader), "DXIL bindings VS reflection failed");
		defer delete shader;

		// test_bindings has: TEXCOORD0 (float3), TEXCOORD1 (float2), TEXCOORD2 (uint4)
		Test.Assert(shader.VertexInputs.Count == 3, scope String()..AppendF("Expected 3 vertex inputs, got {}", shader.VertexInputs.Count));

		let pos = TestHelper.FindVertexInputByLocation(shader, 0);
		Test.Assert(pos != null, "Should have vertex input at location 0");
		if (pos != null)
			Test.Assert(pos.Value.Format == .Float32x3, scope String()..AppendF("Position should be Float32x3, got {}", pos.Value.Format));

		let tex = TestHelper.FindVertexInputByLocation(shader, 1);
		Test.Assert(tex != null, "Should have vertex input at location 1");
		if (tex != null)
			Test.Assert(tex.Value.Format == .Float32x2, scope String()..AppendF("TexCoord should be Float32x2, got {}", tex.Value.Format));

		let bones = TestHelper.FindVertexInputByLocation(shader, 2);
		Test.Assert(bones != null, "Should have vertex input at location 2");
		if (bones != null)
			Test.Assert(bones.Value.Format == .Uint32x4, scope String()..AppendF("BoneIds should be Uint32x4, got {}", bones.Value.Format));
	}

	[Test]
	public static void TestComputeThreadGroupSize()
	{
		let bytecode = TestHelper.LoadShader("test_compute.dxil");
		Test.Assert(bytecode != null, "Failed to load test_compute.dxil");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.DXIL, bytecode, "CSMain");
		Test.Assert(result case .Ok(let shader), "DXIL compute shader reflection failed");
		defer delete shader;

		Test.Assert(shader.Stage == .Compute, "Stage should be Compute");
		Test.Assert(shader.ThreadGroupSize[0] == 64, scope String()..AppendF("ThreadGroupSize.x should be 64, got {}", shader.ThreadGroupSize[0]));
		Test.Assert(shader.ThreadGroupSize[1] == 1, scope String()..AppendF("ThreadGroupSize.y should be 1, got {}", shader.ThreadGroupSize[1]));
		Test.Assert(shader.ThreadGroupSize[2] == 1, scope String()..AppendF("ThreadGroupSize.z should be 1, got {}", shader.ThreadGroupSize[2]));
	}

	[Test]
	public static void TestComputeBindings()
	{
		let bytecode = TestHelper.LoadShader("test_compute.dxil");
		Test.Assert(bytecode != null, "Failed to load test_compute.dxil");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.DXIL, bytecode);
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		Test.Assert(shader.Bindings.Count >= 3, scope String()..AppendF("Expected >= 3 bindings, got {}", shader.Bindings.Count));

		let @params = TestHelper.FindBinding(shader, "Params");
		if (@params != null)
			Test.Assert(@params.Value.Type == .UniformBuffer, "Params should be UniformBuffer");

		let input = TestHelper.FindBinding(shader, "InputBuffer");
		if (input != null)
			Test.Assert(input.Value.Type == .StorageBufferReadOnly, "InputBuffer should be StorageBufferReadOnly");

		let output = TestHelper.FindBinding(shader, "OutputBuffer");
		if (output != null)
			Test.Assert(output.Value.Type == .StorageBufferReadWrite, "OutputBuffer should be StorageBufferReadWrite");
	}

	[Test]
	public static void TestVertexShaderHasNoThreadGroupSize()
	{
		let bytecode = TestHelper.LoadShader("triangle_vs.dxil");
		Test.Assert(bytecode != null, "Failed to load triangle_vs.dxil");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.DXIL, bytecode);
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		Test.Assert(shader.ThreadGroupSize[0] == 0, "VS should have ThreadGroupSize.x == 0");
		Test.Assert(shader.ThreadGroupSize[1] == 0, "VS should have ThreadGroupSize.y == 0");
		Test.Assert(shader.ThreadGroupSize[2] == 0, "VS should have ThreadGroupSize.z == 0");
	}
}
