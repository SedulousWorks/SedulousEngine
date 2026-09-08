using System;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Resource;

namespace Sedulous.Materials.Resource.Tests;

/// What a source targeting the built in forward shader has to declare, and what happens to
/// one that does not.
class ForwardMaterialContractTests
{
	/// The forward constant buffer is BaseColor at zero, Metallic and Roughness after it,
	/// EmissiveColor on the next sixteen byte row, then the three stragglers packed into
	/// the row after that. The builder's packing has to land on exactly those offsets,
	/// because the shader was compiled against them.
	[Test]
	public static void ThePbrPresetPacksOntoTheShadersOffsets()
	{
		let material = MaterialPresets.CreatePbr("m");
		defer delete material;

		Test.Assert(material.FindProperty("BaseColor", let baseColor));
		Test.Assert((baseColor.Offset == 0) && (baseColor.Size == 16));

		Test.Assert(material.FindProperty("Metallic", let metallic) && (metallic.Offset == 16));
		Test.Assert(material.FindProperty("Roughness", let roughness) && (roughness.Offset == 20));

		// Aligned up past the two scalars rather than packed against them.
		Test.Assert(material.FindProperty("EmissiveColor", let emissive));
		Test.Assert((emissive.Offset == 32) && (emissive.Size == 16));

		Test.Assert(material.FindProperty("OcclusionStrength", let occlusion)
			&& (occlusion.Offset == 48));
		Test.Assert(material.FindProperty("NormalScale", let normalScale)
			&& (normalScale.Offset == 52));
		Test.Assert(material.FindProperty("AlphaCutoff", let cutoff) && (cutoff.Offset == 56));

		Test.Assert(material.UniformDataSize == 64, "rounded up from sixty");

		// Black by default, so declaring the field changed nothing visually.
		let emissiveDefault = (float*)(material.DefaultUniformData.Ptr + 32);
		Test.Assert((emissiveDefault[0] == 0.0f) && (emissiveDefault[1] == 0.0f)
			&& (emissiveDefault[2] == 0.0f));
	}

	/// A source authored before those properties existed produces a SHORT buffer, and the
	/// shader then reads past the end of it.
	[Test]
	public static void AForwardSourceMissingThePropertiesIsIncomplete()
	{
		let builder = scope MaterialBuilder("legacy");
		let old = builder
			..Shader("forward")
			..VertexLayout(.Mesh)
			..Color("BaseColor", .(0.5f, 0.25f, 0.125f, 1))
			..Float("Metallic", 1.0f)
			..Float("Roughness", 0.25f)
			..Texture("AlbedoMap")
			..Sampler("MainSampler")
			.Build();
		defer delete old;

		let source = scope MaterialSource();
		MaterialSource.FromMaterial(old, .(), source);

		let missing = scope String();
		Test.Assert(!ForwardMaterialContract.IsComplete(source, missing));
		Test.Assert(missing == "EmissiveColor", "the first one it is short of");
		Test.Assert(source.PropertyNames.Count == 5, "and nothing was appended to fix it");
	}

	[Test]
	public static void ACurrentForwardSourceIsComplete()
	{
		let material = MaterialPresets.CreatePbr("current");
		defer delete material;

		let source = scope MaterialSource();
		MaterialSource.FromMaterial(material, .(), source);
		Test.Assert(ForwardMaterialContract.IsComplete(source));
	}

	/// A source for any other shader passes UNEXAMINED: a custom shader declares its own
	/// block, and this layer knows nothing about it.
	[Test]
	public static void ANonForwardSourceIsNotExamined()
	{
		let unlit = scope MaterialSource();
		unlit.ShaderName.Set("unlit");
		Test.Assert(ForwardMaterialContract.IsComplete(unlit));

		let custom = scope MaterialSource();
		custom.ShaderName.Set("my_shader");
		Test.Assert(ForwardMaterialContract.IsComplete(custom));

		// Including one with no shader name at all.
		let anonymous = scope MaterialSource();
		Test.Assert(ForwardMaterialContract.IsComplete(anonymous));
	}

	/// The factory REFUSES a stale source rather than upgrading it in memory. Upgrading
	/// would need this layer to know the offsets the shader expects, which is the coupling
	/// the data driven model exists to avoid, and a source that silently repairs itself on
	/// load never gets re-cooked.
	[Test]
	public static void TheFactoryRefusesAStaleForwardSource()
	{
		let fixture = scope MaterialFixture("scratch_material_stale");

		let builder = scope MaterialBuilder("legacy");
		let old = builder
			..Shader("forward")
			..Color("BaseColor", .(1, 1, 1, 1))
			..Float("Metallic", 0.0f)
			..Float("Roughness", 0.5f)
			.Build();
		defer delete old;

		let source = scope MaterialSource();
		MaterialSource.FromMaterial(old, .(), source);

		let id = fixture.CookMaterial("legacy", source);
		let material = fixture.Manager.Bind<Material>(id);

		Test.Assert(material.Get == null);
		Test.Assert(material.State == .Failed, "refused, not quietly half built");
	}

	/// And a COMPLETE forward source builds, so the refusal is about the missing
	/// properties rather than about the shader name.
	[Test]
	public static void TheFactoryAcceptsACompleteForwardSource()
	{
		let fixture = scope MaterialFixture("scratch_material_complete");

		let material = MaterialPresets.CreatePbr("current");
		defer delete material;
		let source = scope MaterialSource();
		MaterialSource.FromMaterial(material, .(), source);

		let id = fixture.CookMaterial("current", source);
		let built = fixture.Manager.Bind<Material>(id);

		Test.Assert(built.Get != null);
		Test.Assert(built.Get.ShaderName == "forward");
		Test.Assert(built.Get.UniformDataSize == 64);
	}
}
