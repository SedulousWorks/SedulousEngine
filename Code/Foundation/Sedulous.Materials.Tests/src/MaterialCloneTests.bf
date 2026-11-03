using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Materials;

namespace Sedulous.Materials.Tests;

/// Material.Clone: a copy with its own uid and everything else the same, for a caller that draws a
/// variant without touching the shared material; a change to the copy leaves the original.
class MaterialCloneTests
{
	/// A view stand-in, never bound.
	private class StubView : ITextureView
	{
		public uint64 Id = TextureViewIds.Next();
		public TextureViewDesc Desc => .();
		public ITexture Texture => null;
		public uint64 UniqueId => Id;
	}

	[Test]
	public static void ACopyHasItsOwnUidAndEverythingElseTheSameChangingItLeavesTheOriginal()
	{
		let builder = scope MaterialBuilder("pbr");
		let material = builder
			..Shader("forward")
			..Flags(.NormalMap)
			..Color("baseColor", .(1, 0, 0, 1))
			..Float("roughness", 0.5f)
			..Texture("albedoMap")
			..Texture("normalMap")
			.Build();
		defer delete material;
		let albedo = scope StubView();
		material.SetDefaultTexture("albedoMap", albedo);
		material.SamplerU = .ClampToEdge;

		let copy = material.Clone();
		defer delete copy;
		Test.Assert(copy.Uid != material.Uid);
		Test.Assert(copy.Name == material.Name);
		Test.Assert(copy.ShaderName == material.ShaderName);
		Test.Assert(copy.ShaderFlags == material.ShaderFlags);
		Test.Assert(copy.Pipeline == material.Pipeline);
		Test.Assert(copy.Pipeline.ShaderName.Ptr == copy.ShaderName.Ptr, "its own shader name, not a view of the original's");
		Test.Assert(copy.SamplerU == .ClampToEdge);
		Test.Assert(copy.PropertyCount == material.PropertyCount);
		Test.Assert(copy.UniformDataSize == material.UniformDataSize);
		Test.Assert(copy.GetPropertyIndex("roughness") == material.GetPropertyIndex("roughness"));
		Test.Assert(((float*)copy.DefaultUniformData.Ptr)[0] == 1.0f);
		let albedoIndex = copy.GetPropertyIndex("albedoMap");
		Test.Assert(albedoIndex >= 0);
		Test.Assert(copy.GetDefaultTexture(albedoIndex) === albedo);

		// The copy drawn without its texture: the original keeps it.
		copy.SetDefaultTexture("albedoMap", null);
		copy.SetDefaultFloat("roughness", 0.9f);
		Test.Assert(copy.GetDefaultTexture(albedoIndex) == null);
		Test.Assert(material.GetDefaultTexture(material.GetPropertyIndex("albedoMap")) === albedo);
		Test.Assert(material.FindProperty("roughness", let roughness));
		Test.Assert(*(float*)(material.DefaultUniformData.Ptr + roughness.Offset) == 0.5f);
	}
}
