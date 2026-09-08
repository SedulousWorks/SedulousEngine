using System;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.Shaders;

namespace Sedulous.Materials.Tests;

/// Authoring a material: the uniform layout the builder lays out, and the properties it
/// declares.
class MaterialBuilderTests
{
	[Test]
	public static void TheBuilderLaysOutUniformsAndDeclaresProperties()
	{
		let builder = scope MaterialBuilder("pbr");
		let material = builder
			..Shader("forward")
			..Flags(.NormalMap)
			..Color("baseColor", .(1, 0, 0, 1))
			..Float("roughness", 0.5f)
			..Texture("albedoMap")
			..Texture("normalMap")
			..Sampler("linearSampler")
			.Build();
		defer delete material;

		Test.Assert(material.IsValid);
		Test.Assert(material.ShaderName == "forward");
		Test.Assert(material.ShaderFlags == .NormalMap);
		Test.Assert(material.Pipeline.ShaderName == "forward", "the config mirrors the shader");
		Test.Assert(material.PropertyCount == 5);

		// Sixteen for the vector plus four for the scalar, rounded to thirty two: WebGPU
		// validates the bound range against the PADDED buffer.
		Test.Assert(material.UniformDataSize == 32);

		Test.Assert(material.GetPropertyIndex("roughness") == 1);
		Test.Assert(material.GetPropertyIndex("missing") == -1);

		Test.Assert(material.FindProperty("roughness", let roughness));
		Test.Assert(roughness.Offset == 16, "the vector before it took a whole slot");
		Test.Assert(roughness.IsUniform);

		let defaults = material.DefaultUniformData;
		Test.Assert(defaults.Length == 32);
		let seeded = (float*)defaults.Ptr;
		Test.Assert(seeded[0] == 1.0f, "the seeded base colour");
		Test.Assert(seeded[1] == 0.0f);
	}

	/// A three component vector occupies SIXTEEN bytes. Packing it tightly would put every
	/// following member where the shader does not read from.
	[Test]
	public static void AThreeComponentVectorTakesAWholeSlot()
	{
		let builder = scope MaterialBuilder("m");
		let material = builder
			..Shader("s")
			..Float("a")
			..Float3("v")
			..Float("b")
			.Build();
		defer delete material;

		Test.Assert(material.FindProperty("a", let a));
		Test.Assert(material.FindProperty("v", let v));
		Test.Assert(material.FindProperty("b", let b));

		Test.Assert(a.Offset == 0);
		Test.Assert(v.Offset == 16, "aligned up past the scalar");
		Test.Assert(v.Size == 12, "declared as twelve...");
		Test.Assert(b.Offset == 32, "...but consuming sixteen");
		Test.Assert(material.UniformDataSize == 48);
	}

	/// Scalars and two component vectors pack tightly, which is the whole reason the
	/// alignment rule is per kind rather than blanket.
	[Test]
	public static void ScalarsAndPairsPackTightly()
	{
		let builder = scope MaterialBuilder("m");
		let material = builder..Shader("s")..Float("a")..Float2("b")..Float("c").Build();
		defer delete material;

		Test.Assert(material.FindProperty("a", let a) && (a.Offset == 0));
		Test.Assert(material.FindProperty("b", let b) && (b.Offset == 4));
		Test.Assert(material.FindProperty("c", let c) && (c.Offset == 12));
		Test.Assert(material.UniformDataSize == 16);
	}

	/// Binding ordinals run in DECLARATION order across every kind, uniforms included.
	[Test]
	public static void BindingsRunInDeclarationOrder()
	{
		let builder = scope MaterialBuilder("m");
		let material = builder
			..Shader("s")..Float("a")..Texture("t")..Sampler("s0")..Float("b").Build();
		defer delete material;

		for (int i = 0; i < material.PropertyCount; i++)
			Test.Assert(material.GetProperty(i).Binding == (uint32)i);
	}

	/// A texture or a sampler carries no uniform data at all, so declaring one must not
	/// grow the buffer.
	[Test]
	public static void ResourcePropertiesCarryNoUniformData()
	{
		let builder = scope MaterialBuilder("m");
		let material = builder..Shader("s")..Texture("t")..TextureCube("c")..Sampler("s0").Build();
		defer delete material;

		Test.Assert(material.UniformDataSize == 0);
		Test.Assert(material.DefaultUniformData.IsEmpty);
		Test.Assert(material.GetProperty(0).IsTexture);
		Test.Assert(material.GetProperty(1).IsTexture, "a cube is a texture");
		Test.Assert(material.GetProperty(2).IsSampler);
		Test.Assert(!material.GetProperty(2).IsUniform);
	}

	/// A material with no shader cannot draw, which is what makes it invalid rather than
	/// merely empty.
	[Test]
	public static void AMaterialWithNoShaderIsInvalid()
	{
		let builder = scope MaterialBuilder("m");
		let material = builder.Build();
		defer delete material;

		Test.Assert(!material.IsValid);
		Test.Assert(material.Name == "m");
	}

	/// Every material gets its own identity, because a renderer's caches key on it and a
	/// reload reuses addresses.
	[Test]
	public static void EveryMaterialHasItsOwnUid()
	{
		let first = MaterialPresets.CreateUnlit("a");
		defer delete first;
		let second = MaterialPresets.CreateUnlit("b");
		defer delete second;

		Test.Assert(first.Uid != 0);
		Test.Assert(first.Uid != second.Uid);
	}

	/// The pair of presets an importer builds, in the order the forward pass expects.
	[Test]
	public static void ThePbrPresetDeclaresTheStandardSet()
	{
		let material = MaterialPresets.CreatePbr("m", .(1, 0, 0, 1), 0.25f, 0.75f);
		defer delete material;

		Test.Assert(material.ShaderName == "forward");
		Test.Assert(material.Pipeline.VertexLayout == .Mesh);
		Test.Assert(material.PropertyCount == 13, "seven uniforms, five maps, one sampler");

		Test.Assert(material.FindProperty("Metallic", let metallic) && metallic.IsUniform);
		Test.Assert(material.FindProperty("AlbedoMap", let albedo) && albedo.IsTexture);
		Test.Assert(material.FindProperty("MainSampler", let sampler) && sampler.IsSampler);

		// The maps come out in the order the bind group contract expects.
		Test.Assert(material.GetPropertyIndex("AlbedoMap") == 7);
		Test.Assert(material.GetPropertyIndex("NormalMap") == 8);
		Test.Assert(material.GetPropertyIndex("MetallicRoughnessMap") == 9);
		Test.Assert(material.GetPropertyIndex("OcclusionMap") == 10);
		Test.Assert(material.GetPropertyIndex("EmissiveMap") == 11);
	}

	[Test]
	public static void TheUnlitPresetIsAlbedoTimesABaseColour()
	{
		let material = MaterialPresets.CreateUnlit("m", .(0, 1, 0, 1));
		defer delete material;

		Test.Assert(material.ShaderName == "unlit");
		Test.Assert(material.PropertyCount == 3);
		// The SAME vertex path as the lit one, so it still casts shadows.
		Test.Assert(material.Pipeline.VertexLayout == .Mesh);

		let defaults = (float*)material.DefaultUniformData.Ptr;
		Test.Assert(defaults[1] == 1.0f, "the green it was given");
	}

	/// The presets that change two things at once change both.
	[Test]
	public static void TheStateShorthandsSetBothHalves()
	{
		let transparent = scope MaterialBuilder("t");
		let a = transparent..Shader("s")..Transparent().Build();
		defer delete a;
		Test.Assert(a.Pipeline.BlendMode == .AlphaBlend);
		Test.Assert(a.Pipeline.DepthMode == .ReadOnly, "or it occludes what blends after it");

		let additive = scope MaterialBuilder("a");
		let b = additive..Shader("s")..Additive().Build();
		defer delete b;
		Test.Assert(b.Pipeline.BlendMode == .Additive);
		Test.Assert(b.Pipeline.DepthMode == .ReadOnly);

		let doubleSided = scope MaterialBuilder("d");
		let c = doubleSided..Shader("s")..DoubleSided().Build();
		defer delete c;
		Test.Assert(c.Pipeline.CullMode == .None);
	}
}
