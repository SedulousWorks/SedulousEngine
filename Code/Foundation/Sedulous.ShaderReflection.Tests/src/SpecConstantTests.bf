namespace Sedulous.ShaderReflection.Tests;

using System;
using Sedulous.RHI;

/// Phase 8: Specialization constant reflection tests (SPIR-V only).
class SpecConstantTests
{
	[Test]
	public static void TestSPIRVSpecConstantCount()
	{
		let bytecode = TestHelper.LoadShader("test_specconst.spv");
		Test.Assert(bytecode != null, "Failed to load test_specconst.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode, "CSMain");
		Test.Assert(result case .Ok(let shader), "SPIR-V spec constant reflection failed");
		defer delete shader;

		Test.Assert(shader.SpecConstants.Count == 4,
			scope String()..AppendF("Expected 4 spec constants, got {}", shader.SpecConstants.Count));
	}

	[Test]
	public static void TestSPIRVSpecConstantBool()
	{
		let bytecode = TestHelper.LoadShader("test_specconst.spv");
		Test.Assert(bytecode != null, "Failed to load test_specconst.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode, "CSMain");
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		let sc = FindSpecConstant(shader, 0);
		Test.Assert(sc != null, "Should have spec constant with ID 0");
		if (sc != null)
		{
			Test.Assert(sc.Value.Type == .Bool,
				scope String()..AppendF("ENABLE_FEATURE should be Bool, got {}", sc.Value.Type));
			Test.Assert(sc.Value.DefaultValue != 0, "ENABLE_FEATURE default should be true (non-zero)");
			Test.Assert(sc.Value.Name == "ENABLE_FEATURE",
				scope String()..AppendF("Name should be ENABLE_FEATURE, got '{}'", sc.Value.Name));
		}
	}

	[Test]
	public static void TestSPIRVSpecConstantInt()
	{
		let bytecode = TestHelper.LoadShader("test_specconst.spv");
		Test.Assert(bytecode != null, "Failed to load test_specconst.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode, "CSMain");
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		let sc = FindSpecConstant(shader, 1);
		Test.Assert(sc != null, "Should have spec constant with ID 1");
		if (sc != null)
		{
			Test.Assert(sc.Value.Type == .Int32,
				scope String()..AppendF("MODE should be Int32, got {}", sc.Value.Type));
			Test.Assert((int32)sc.Value.DefaultValue == 2,
				scope String()..AppendF("MODE default should be 2, got {}", (int32)sc.Value.DefaultValue));
		}
	}

	[Test]
	public static void TestSPIRVSpecConstantUint()
	{
		let bytecode = TestHelper.LoadShader("test_specconst.spv");
		Test.Assert(bytecode != null, "Failed to load test_specconst.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode, "CSMain");
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		let sc = FindSpecConstant(shader, 2);
		Test.Assert(sc != null, "Should have spec constant with ID 2");
		if (sc != null)
		{
			Test.Assert(sc.Value.Type == .Uint32,
				scope String()..AppendF("TILE_SIZE should be Uint32, got {}", sc.Value.Type));
			Test.Assert(sc.Value.DefaultValue == 16,
				scope String()..AppendF("TILE_SIZE default should be 16, got {}", sc.Value.DefaultValue));
		}
	}

	[Test]
	public static void TestSPIRVSpecConstantFloat()
	{
		let bytecode = TestHelper.LoadShader("test_specconst.spv");
		Test.Assert(bytecode != null, "Failed to load test_specconst.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode, "CSMain");
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		let sc = FindSpecConstant(shader, 3);
		Test.Assert(sc != null, "Should have spec constant with ID 3");
		if (sc != null)
		{
			Test.Assert(sc.Value.Type == .Float32,
				scope String()..AppendF("SCALE should be Float32, got {}", sc.Value.Type));
			let f = *(float*)&sc.Value.DefaultValue;
			Test.Assert(f > 1.49f && f < 1.51f,
				scope String()..AppendF("SCALE default should be ~1.5, got {}", f));
		}
	}

	[Test]
	public static void TestDXILHasNoSpecConstants()
	{
		let bytecode = TestHelper.LoadShader("test_compute.dxil");
		Test.Assert(bytecode != null, "Failed to load test_compute.dxil");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.DXIL, bytecode);
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		Test.Assert(shader.SpecConstants.Count == 0,
			"DXIL shaders should have no specialization constants");
	}

	[Test]
	public static void TestNonSpecConstShaderHasEmpty()
	{
		let bytecode = TestHelper.LoadShader("test_compute.spv");
		Test.Assert(bytecode != null, "Failed to load test_compute.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode);
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		Test.Assert(shader.SpecConstants.Count == 0,
			scope String()..AppendF("Shader without spec constants should have 0, got {}", shader.SpecConstants.Count));
	}

	private static Nullable<ReflectedSpecConstant> FindSpecConstant(ReflectedShader shader, uint32 constantId)
	{
		for (let sc in shader.SpecConstants)
		{
			if (sc.ConstantId == constantId)
				return sc;
		}
		return null;
	}
}
