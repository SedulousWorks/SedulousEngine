using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Materials.Pipeline;
using Sedulous.Materials.Resource;
using Sedulous.Model;

namespace Sedulous.ModelImporter.Tests;

/// What an imported material carries.
///
/// Every authored texture is wired into the material's OWN source rather than only into the
/// model's composite: a material picked straight out of the browser once rendered untextured
/// because only the model spawn path bound anything.
class ModelMaterialWiringTests
{
	private static MaterialSource ReadMaterial(Group group, StringView name, List<Object> owned)
	{
		let instance = group.GetInstance(name);
		Test.Assert(instance != null, scope String(name));
		let object = instance.ReadObject();
		Test.Assert(object != null);
		let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as MaterialAsset;
		Test.Assert(asset != null);
		owned.Add(asset);
		return asset.Source;
	}

	private static Guid SlotId(MaterialSource source, StringView slot)
	{
		for (int i < source.TextureSlots.Count)
		{
			if (source.TextureSlots[i] == slot)
				return source.TextureIds[i];
		}
		return .Empty;
	}

	/// Each authored slot reaches the material, naming the texture asset the same import
	/// created, so the material is self contained.
	[Test]
	public static void EveryAuthoredTextureIsWiredIntoTheMaterialSource()
	{
		let fixture = scope ImportFixture("scratch_model_material_wiring");
		let dropped = scope String();
		fixture.WriteDroppedFile("character.glb", "x", dropped);

		let prepared = scope LoadedModel();
		ModelFixture.Character(prepared.Model);

		let importer = scope ModelFileImporter();
		let imported = importer.Import(dropped, fixture.Context, fixture.RootGroup, null,
			prepared, null);
		Test.Assert(imported case .Ok);
		let group = imported.Value.OwningGroup;

		let owned = scope List<Object>();
		defer { for (let object in owned) delete object; }

		let source = ReadMaterial(group, "Skin", owned);
		Test.Assert(source.ShaderName == "forward"); // a built in shader, so no cook is needed

		Test.Assert(SlotId(source, "AlbedoMap") == group.GetInstance("Texture").Id);
		Test.Assert(SlotId(source, "OcclusionMap") == group.GetInstance("Occlusion").Id);
	}

	/// Authored pipeline state comes across: a masked material is an alpha tested cutout, and
	/// a double sided one stops culling.
	[Test]
	public static void TheAuthoredPipelineStateComesAcross()
	{
		let fixture = scope ImportFixture("scratch_model_material_state");
		let dropped = scope String();
		fixture.WriteDroppedFile("foliage.glb", "x", dropped);

		let prepared = scope LoadedModel();
		let model = prepared.Model;
		let leaf = new ModelMaterial();
		leaf.Name.Set("Leaf");
		leaf.AlphaMode = .Mask;
		leaf.DoubleSided = true;
		model.AddMaterial(leaf);

		let glass = new ModelMaterial();
		glass.Name.Set("Glass");
		glass.AlphaMode = .Blend;
		model.AddMaterial(glass);

		let mesh = MeshFixture.Row("Card", 0.0f, 3, scope uint32[](0, 1, 2));
		mesh.AddPart(.(0, 3, 0));
		model.AddMesh(mesh);
		model.CalculateBounds();

		let importer = scope ModelFileImporter();
		let imported = importer.Import(dropped, fixture.Context, fixture.RootGroup, null,
			prepared, null);
		Test.Assert(imported case .Ok);
		let group = imported.Value.OwningGroup;

		let owned = scope List<Object>();
		defer { for (let object in owned) delete object; }

		let leafSource = ReadMaterial(group, "Leaf", owned);
		Test.Assert(leafSource.BlendMode == .Masked);
		Test.Assert(leafSource.CullMode == .None);

		let glassSource = ReadMaterial(group, "Glass", owned);
		Test.Assert(glassSource.BlendMode == .AlphaBlend);
		Test.Assert(glassSource.CullMode == .Back);
	}

	/// A format supplying metalness and roughness SEPARATELY gets one baked packed texture,
	/// created once for the pair and wired into the packed slot.
	[Test]
	public static void SeparateMetalAndRoughMapsBakeOnceAndWireIn()
	{
		let fixture = scope ImportFixture("scratch_model_material_packed");
		let dropped = scope String();
		fixture.WriteDroppedFile("metal.fbx", "x", dropped);

		let prepared = scope LoadedModel();
		let model = prepared.Model;
		let rough = model.AddTexture(MeshFixture.Gray(200, "rough"));
		let metal = model.AddTexture(MeshFixture.Gray(60, "metal"));

		for (let name in scope String[]("PartA", "PartB"))
		{
			let material = new ModelMaterial();
			material.Name.Set(name);
			material.SeparateRoughnessTextureIndex = rough;
			material.SeparateMetalnessTextureIndex = metal;
			model.AddMaterial(material);
		}

		let mesh = MeshFixture.Row("Body", 0.0f, 3, scope uint32[](0, 1, 2));
		mesh.AddPart(.(0, 3, 0));
		model.AddMesh(mesh);
		model.CalculateBounds();

		let importer = scope ModelFileImporter();
		let imported = importer.Import(dropped, fixture.Context, fixture.RootGroup, null,
			prepared, null);
		Test.Assert(imported case .Ok);
		let group = imported.Value.OwningGroup;

		let packed = group.GetInstance(scope $"mr.packed.{rough}.{metal}");
		Test.Assert(packed != null);

		let owned = scope List<Object>();
		defer { for (let object in owned) delete object; }

		// BOTH materials name the same baked texture: the bake is cached by the pair, so two
		// materials sharing the maps do not each get a copy of it.
		Test.Assert(SlotId(ReadMaterial(group, "PartA", owned), "MetallicRoughnessMap")
			== packed.Id);
		Test.Assert(SlotId(ReadMaterial(group, "PartB", owned), "MetallicRoughnessMap")
			== packed.Id);
	}
}
