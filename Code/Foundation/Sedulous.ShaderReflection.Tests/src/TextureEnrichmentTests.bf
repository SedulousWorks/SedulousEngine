namespace Sedulous.ShaderReflection.Tests;

using System;
using Sedulous.RHI;

/// Phase 7: Texture dimension and multisampled enrichment tests.
class TextureEnrichmentTests
{
	[Test]
	public static void TestSPIRVTextureDimensions()
	{
		let bytecode = TestHelper.LoadShader("test_texdim_ps.spv");
		Test.Assert(bytecode != null, "Failed to load test_texdim_ps.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode, "PSMain");
		Test.Assert(result case .Ok(let shader), "SPIR-V texdim PS reflection failed");
		defer delete shader;

		Test.Assert(shader.Stage == .Fragment, "Stage should be Fragment");

		let tex2d = TestHelper.FindBinding(shader, "Tex2D");
		Test.Assert(tex2d != null, "Should have Tex2D binding");
		if (tex2d != null)
		{
			Test.Assert(tex2d.Value.TextureDimension == .Texture2D,
				scope String()..AppendF("Tex2D should be Texture2D, got {}", tex2d.Value.TextureDimension));
			Test.Assert(!tex2d.Value.TextureMultisampled, "Tex2D should not be multisampled");
		}

		let texCube = TestHelper.FindBinding(shader, "TexCube");
		Test.Assert(texCube != null, "Should have TexCube binding");
		if (texCube != null)
			Test.Assert(texCube.Value.TextureDimension == .TextureCube,
				scope String()..AppendF("TexCube should be TextureCube, got {}", texCube.Value.TextureDimension));

		let tex2dArr = TestHelper.FindBinding(shader, "Tex2DArr");
		Test.Assert(tex2dArr != null, "Should have Tex2DArr binding");
		if (tex2dArr != null)
			Test.Assert(tex2dArr.Value.TextureDimension == .Texture2DArray,
				scope String()..AppendF("Tex2DArr should be Texture2DArray, got {}", tex2dArr.Value.TextureDimension));

		let tex3d = TestHelper.FindBinding(shader, "Tex3D");
		Test.Assert(tex3d != null, "Should have Tex3D binding");
		if (tex3d != null)
			Test.Assert(tex3d.Value.TextureDimension == .Texture3D,
				scope String()..AppendF("Tex3D should be Texture3D, got {}", tex3d.Value.TextureDimension));
	}

	[Test]
	public static void TestDXILTextureDimensions()
	{
		let bytecode = TestHelper.LoadShader("test_texdim_ps.dxil");
		Test.Assert(bytecode != null, "Failed to load test_texdim_ps.dxil");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.DXIL, bytecode, "PSMain");
		Test.Assert(result case .Ok(let shader), "DXIL texdim PS reflection failed");
		defer delete shader;

		Test.Assert(shader.Stage == .Fragment, "Stage should be Fragment");

		let tex2d = TestHelper.FindBinding(shader, "Tex2D");
		Test.Assert(tex2d != null, "Should have Tex2D binding");
		if (tex2d != null)
		{
			Test.Assert(tex2d.Value.TextureDimension == .Texture2D,
				scope String()..AppendF("Tex2D should be Texture2D, got {}", tex2d.Value.TextureDimension));
			Test.Assert(!tex2d.Value.TextureMultisampled, "Tex2D should not be multisampled");
		}

		let texCube = TestHelper.FindBinding(shader, "TexCube");
		Test.Assert(texCube != null, "Should have TexCube binding");
		if (texCube != null)
			Test.Assert(texCube.Value.TextureDimension == .TextureCube,
				scope String()..AppendF("TexCube should be TextureCube, got {}", texCube.Value.TextureDimension));

		let tex2dArr = TestHelper.FindBinding(shader, "Tex2DArr");
		Test.Assert(tex2dArr != null, "Should have Tex2DArr binding");
		if (tex2dArr != null)
			Test.Assert(tex2dArr.Value.TextureDimension == .Texture2DArray,
				scope String()..AppendF("Tex2DArr should be Texture2DArray, got {}", tex2dArr.Value.TextureDimension));

		let tex3d = TestHelper.FindBinding(shader, "Tex3D");
		Test.Assert(tex3d != null, "Should have Tex3D binding");
		if (tex3d != null)
			Test.Assert(tex3d.Value.TextureDimension == .Texture3D,
				scope String()..AppendF("Tex3D should be Texture3D, got {}", tex3d.Value.TextureDimension));
	}

	[Test]
	public static void TestNonTextureBindingHasDefaultDimension()
	{
		let bytecode = TestHelper.LoadShader("test_compute.spv");
		Test.Assert(bytecode != null, "Failed to load test_compute.spv");
		defer delete bytecode;

		let result = ShaderReflection.Reflect(.SPIRV, bytecode);
		Test.Assert(result case .Ok(let shader), "Reflection failed");
		defer delete shader;

		// Non-texture bindings should have default Texture2D dimension
		for (let b in shader.Bindings)
		{
			Test.Assert(b.TextureDimension == .Texture2D,
				scope String()..AppendF("Non-texture binding '{}' should have default Texture2D dimension", b.Name));
			Test.Assert(!b.TextureMultisampled,
				scope String()..AppendF("Non-texture binding '{}' should not be multisampled", b.Name));
		}
	}
}
