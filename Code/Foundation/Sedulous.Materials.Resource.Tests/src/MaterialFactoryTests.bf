using System;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Resource;
using Sedulous.RHI;

namespace Sedulous.Materials.Resource.Tests;

/// Building an authored source into a runtime material, and the dependency edges the build
/// records on the way.
class MaterialFactoryTests
{
	/// A source for a shader that is NOT the forward one, so the contract check passes and
	/// each test can state only what it is about.
	private static MaterialSource CustomSource(StringView name = "m")
	{
		let material = MaterialPresets.CreateUnlit(name, .(0.25f, 0.5f, 0.75f, 1), "custom");
		defer delete material;

		let source = new MaterialSource();
		MaterialSource.FromMaterial(material, .(), source);
		return source;
	}

	[Test]
	public static void ASourceBuildsIntoARuntimeMaterial()
	{
		let fixture = scope MaterialFixture("scratch_material_build");
		let source = CustomSource("painted");
		defer delete source;
		source.BlendMode = .Additive;
		source.DepthMode = .ReadOnly;
		source.CullMode = .None;
		source.SamplerU = (uint8)AddressMode.ClampToEdge;

		let id = fixture.CookMaterial("painted", source);
		let material = fixture.Manager.Bind<Material>(id);

		Test.Assert(material.Get != null);
		Test.Assert(material.State == .Ready);
		Test.Assert(material.Get.Name == "painted");
		Test.Assert(material.Get.ShaderName == "custom", "the builtin named directly");
		Test.Assert(material.Get.IsValid);

		// The declared layout came through verbatim, offsets included: the shader was
		// compiled against those, so recomputing them would be a second opinion.
		Test.Assert(material.Get.PropertyCount == 3);
		Test.Assert(material.Get.FindProperty("BaseColor", let baseColor));
		Test.Assert(baseColor.Offset == 0);
		Test.Assert(material.Get.FindProperty("AlbedoMap", let albedo) && albedo.IsTexture);

		let defaults = (float*)material.Get.DefaultUniformData.Ptr;
		Test.Assert(defaults[0] == 0.25f, "the authored defaults were restored");
		Test.Assert(defaults[2] == 0.75f);

		// The pipeline mirrors what the source asked for.
		Test.Assert(material.Get.Pipeline.BlendMode == .Additive);
		Test.Assert(material.Get.Pipeline.DepthMode == .ReadOnly);
		Test.Assert(material.Get.Pipeline.CullMode == .None);
		Test.Assert(material.Get.Pipeline.VertexLayout == .Mesh);
		Test.Assert(material.Get.Pipeline.ShaderName == "custom");
		Test.Assert(material.Get.SamplerU == .ClampToEdge);
	}

	/// Naming a cooked shader resolves through it, and the BIND is what records the
	/// material to shader edge: reloading the shader is what brings the material back.
	[Test]
	public static void ACookedShaderResolvesAndRecordsTheEdge()
	{
		let fixture = scope MaterialFixture("scratch_material_shader");
		let shaderId = fixture.CookShader("lit");

		let source = CustomSource("uses_lit");
		defer delete source;
		source.ShaderId = shaderId;
		// Deliberately different, to prove the resource wins over the fallback.
		source.ShaderName.Set("ignored");

		let id = fixture.CookMaterial("uses_lit", source);
		let material = fixture.Manager.Bind<Material>(id);

		Test.Assert(material.Get != null);
		Test.Assert(material.Get.ShaderName == "lit", "the resource, not the fallback name");

		let dependencies = scope System.Collections.List<Guid>();
		fixture.Manager.GetDependencies(id, dependencies);
		Test.Assert(dependencies.Contains(shaderId), "the edge a shader reload travels");
	}

	/// A shader id that resolves to nothing falls back to the name rather than failing: a
	/// material whose shader is not cooked yet still describes itself.
	[Test]
	public static void AnUnresolvableShaderIdFallsBackToTheName()
	{
		let fixture = scope MaterialFixture("scratch_material_noshader");

		let source = CustomSource("orphan");
		defer delete source;
		source.ShaderId = Guid.Create();
		source.ShaderName.Set("custom");

		let id = fixture.CookMaterial("orphan", source);
		let material = fixture.Manager.Bind<Material>(id);

		Test.Assert(material.Get != null);
		Test.Assert(material.Get.ShaderName == "custom");
	}

	/// The stored texture slots are resolved and installed as defaults, which is what makes
	/// a cooked material self contained.
	[Test]
	public static void TheTextureSlotsAreBoundAndRecordTheirEdges()
	{
		let fixture = scope MaterialFixture("scratch_material_textures");
		let textureId = fixture.CookTexture("albedo");

		let source = CustomSource("textured");
		defer delete source;
		source.TextureSlots.Add(new String("AlbedoMap"));
		source.TextureIds.Add(textureId);

		let id = fixture.CookMaterial("textured", source);
		let material = fixture.Manager.Bind<Material>(id);

		Test.Assert(material.Get != null);
		let slot = material.Get.GetPropertyIndex("AlbedoMap");
		Test.Assert(slot >= 0);
		Test.Assert(material.Get.GetDefaultTexture(slot) != null, "the slot was filled");

		let dependencies = scope System.Collections.List<Guid>();
		fixture.Manager.GetDependencies(id, dependencies);
		Test.Assert(dependencies.Contains(textureId), "the edge a texture reload travels");
	}

	/// A slot that cannot be filled leaves the material usable: the system substitutes a
	/// neutral texture, so a material whose textures are not cooked yet still draws.
	[Test]
	public static void AnUnbindableSlotLeavesTheMaterialUsable()
	{
		let fixture = scope MaterialFixture("scratch_material_missingtex");

		let source = CustomSource("hopeful");
		defer delete source;
		source.TextureSlots.Add(new String("AlbedoMap"));
		source.TextureIds.Add(Guid.Create());
		// A slot the material's layout does not have, which is the other way this goes
		// wrong and must also not be fatal.
		source.TextureSlots.Add(new String("NoSuchMap"));
		source.TextureIds.Add(Guid.Create());

		let id = fixture.CookMaterial("hopeful", source);
		let material = fixture.Manager.Bind<Material>(id);

		Test.Assert(material.Get != null, "an unbindable slot is not a failed material");
		Test.Assert(material.Get.GetDefaultTexture(material.Get.GetPropertyIndex("AlbedoMap"))
			== null, "left unbound for the system to fill");
	}

	/// A NIL id is not a failed bind, it is a slot nobody assigned. It must not even be
	/// looked up.
	[Test]
	public static void ANilTextureIdIsSkipped()
	{
		let fixture = scope MaterialFixture("scratch_material_niltex");

		let source = CustomSource("blank");
		defer delete source;
		source.TextureSlots.Add(new String("AlbedoMap"));
		source.TextureIds.Add(.());

		let id = fixture.CookMaterial("blank", source);
		let material = fixture.Manager.Bind<Material>(id);

		Test.Assert(material.Get != null);
		let dependencies = scope System.Collections.List<Guid>();
		fixture.Manager.GetDependencies(id, dependencies);
		Test.Assert(dependencies.IsEmpty, "nothing was bound, so nothing was recorded");
	}

	/// Something else stored under the material type name is not a material.
	[Test]
	public static void AnInstanceHoldingSomethingElseFailsToBuild()
	{
		let fixture = scope MaterialFixture("scratch_material_wrongtype");

		let instance = fixture.Database.RootGroup.CreateInstance("stranger", "demo.NotAMaterial");
		let source = CustomSource("stranger");
		defer delete source;
		instance.WriteObject(source).IgnoreError();

		let material = fixture.Manager.Bind<Material>(instance.Id);
		Test.Assert(material.Get == null);
		Test.Assert(material.State == .Failed);
	}
}
