namespace Sedulous.ShaderReflection.Tests;

using System;
using Sedulous.RHI;

/// Phase 8: Mesh shader reflection tests.
class MeshShaderTests
{
	[Test]
	public static void TestSPIRVMeshShaderStage()
	{
		let bytecode = TestHelper.LoadShader("test_mesh.spv");
		Test.Assert(bytecode != null, "Failed to load test_mesh.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode, "MSMain");
		Test.Assert(result case .Ok(let shader), "SPIR-V mesh shader reflection failed");
		defer delete shader;

		Test.Assert(shader.Stage == .Mesh, scope String()..AppendF("Stage should be Mesh, got {}", shader.Stage));
	}

	[Test]
	public static void TestSPIRVMeshShaderThreadGroupSize()
	{
		let bytecode = TestHelper.LoadShader("test_mesh.spv");
		Test.Assert(bytecode != null, "Failed to load test_mesh.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode, "MSMain");
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		Test.Assert(shader.ThreadGroupSize[0] == 32,
			scope String()..AppendF("ThreadGroupSize.x should be 32, got {}", shader.ThreadGroupSize[0]));
		Test.Assert(shader.ThreadGroupSize[1] == 1,
			scope String()..AppendF("ThreadGroupSize.y should be 1, got {}", shader.ThreadGroupSize[1]));
		Test.Assert(shader.ThreadGroupSize[2] == 1,
			scope String()..AppendF("ThreadGroupSize.z should be 1, got {}", shader.ThreadGroupSize[2]));
	}

	[Test]
	public static void TestSPIRVMeshShaderOutputTopology()
	{
		let bytecode = TestHelper.LoadShader("test_mesh.spv");
		Test.Assert(bytecode != null, "Failed to load test_mesh.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode, "MSMain");
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		Test.Assert(shader.MeshOutput.Topology == .Triangles,
			scope String()..AppendF("Output topology should be Triangles, got {}", shader.MeshOutput.Topology));
	}

	[Test]
	public static void TestSPIRVMeshShaderOutputCounts()
	{
		let bytecode = TestHelper.LoadShader("test_mesh.spv");
		Test.Assert(bytecode != null, "Failed to load test_mesh.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode, "MSMain");
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		Test.Assert(shader.MeshOutput.MaxVertices == 64,
			scope String()..AppendF("MaxVertices should be 64, got {}", shader.MeshOutput.MaxVertices));
		Test.Assert(shader.MeshOutput.MaxPrimitives == 126,
			scope String()..AppendF("MaxPrimitives should be 126, got {}", shader.MeshOutput.MaxPrimitives));
	}

	[Test]
	public static void TestSPIRVMeshShaderBindings()
	{
		let bytecode = TestHelper.LoadShader("test_mesh.spv");
		Test.Assert(bytecode != null, "Failed to load test_mesh.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode);
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		// Mesh shader has: MeshParams (UB b0,s0)
		let meshParams = TestHelper.FindBinding(shader, "type.MeshParams");
		Test.Assert(meshParams != null, "Should have MeshParams binding");
		if (meshParams != null)
		{
			Test.Assert(meshParams.Value.Type == .UniformBuffer, "MeshParams should be UniformBuffer");
			Test.Assert(meshParams.Value.Stages == .Mesh, "MeshParams stages should be Mesh");
		}
	}

	[Test]
	public static void TestDXILMeshShaderStage()
	{
		let bytecode = TestHelper.LoadShader("test_mesh.dxil");
		Test.Assert(bytecode != null, "Failed to load test_mesh.dxil");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.DXIL, bytecode, "MSMain");
		Test.Assert(result case .Ok(let shader), "DXIL mesh shader reflection failed");
		defer delete shader;

		Test.Assert(shader.Stage == .Mesh, scope String()..AppendF("Stage should be Mesh, got {}", shader.Stage));
	}

	[Test]
	public static void TestDXILMeshShaderThreadGroupSize()
	{
		let bytecode = TestHelper.LoadShader("test_mesh.dxil");
		Test.Assert(bytecode != null, "Failed to load test_mesh.dxil");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.DXIL, bytecode, "MSMain");
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		Test.Assert(shader.ThreadGroupSize[0] == 32,
			scope String()..AppendF("ThreadGroupSize.x should be 32, got {}", shader.ThreadGroupSize[0]));
	}

	[Test]
	public static void TestDXILMeshShaderBindings()
	{
		let bytecode = TestHelper.LoadShader("test_mesh.dxil");
		Test.Assert(bytecode != null, "Failed to load test_mesh.dxil");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.DXIL, bytecode);
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		let meshParams = TestHelper.FindBinding(shader, "MeshParams");
		Test.Assert(meshParams != null, "Should have MeshParams binding");
		if (meshParams != null)
			Test.Assert(meshParams.Value.Type == .UniformBuffer, "MeshParams should be UniformBuffer");
	}

	[Test]
	public static void TestNonMeshShaderHasEmptyMeshOutput()
	{
		let bytecode = TestHelper.LoadShader("test_compute.spv");
		Test.Assert(bytecode != null, "Failed to load test_compute.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode);
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		Test.Assert(shader.MeshOutput.Topology == .Unknown, "Non-mesh should have Unknown topology");
		Test.Assert(shader.MeshOutput.MaxVertices == 0, "Non-mesh should have 0 MaxVertices");
		Test.Assert(shader.MeshOutput.MaxPrimitives == 0, "Non-mesh should have 0 MaxPrimitives");
	}
}
