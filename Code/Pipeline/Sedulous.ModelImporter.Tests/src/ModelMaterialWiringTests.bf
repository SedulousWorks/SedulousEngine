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

	// Each material made on the built-in its shading model names, as its file authored it (Raptor's
	// phong-material spec), by the one function both cooks make materials with.
	[Test]
	public static void AMaterialIsMadeOnTheBuiltInItsShadingModelNamesItsMapsWired()
	{
		let model = scope Model();
		ModelMaterial Add(ShadingModel shading)
		{
			let material = new ModelMaterial();
			material.Shading = shading;
			material.BaseColorTextureIndex = 0;
			material.NormalTextureIndex = 1;
			model.AddMaterial(material);
			return material;
		}
		let phong = Add(.Phong);
		phong.SpecularColor = .(0.5f, 0.25f, 0.125f);
		phong.SpecularTextureIndex = 2;
		phong.Shininess = 32.0f;
		let lambert = Add(.Lambert);
		lambert.SpecularColor = .(0.5f, 0.5f, 0.5f); // a Lambert material has no highlight, whatever it says
		lambert.SpecularTextureIndex = 2;
		Add(.Unlit);
		let pbr = Add(.Pbr);
		pbr.SeparateRoughnessTextureIndex = 3;
		pbr.OcclusionTextureIndex = 4;

		let textures = scope List<Guid>();
		for (uint8 t = 1; t <= 5; t++)
			textures.Add(Guid(t, 0, 0, 0, 0, 0, 0, 0, 0, 0, t));
		int bakes = 0;
		delegate Guid(int32 roughIndex, int32 metalIndex) packed = scope [&] (roughIndex, metalIndex) =>
			{
				bakes++;
				return Guid(9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9);
			};
		void Slots(MaterialAsset asset, String outText)
		{
			for (let slot in asset.Source.TextureSlots)
			{
				if (!outText.IsEmpty)
					outText.Append(' ');
				outText.Append(slot);
			}
		}
		Float4 Uniform(MaterialAsset asset, StringView name)
		{
			var value = Float4(0, 0, 0, 0);
			let source = asset.Source;
			for (int i < source.PropertyNames.Count)
			{
				if (source.PropertyNames[i] == name)
					Internal.MemCpy(&value, source.UniformDefaults.Ptr + source.PropertyOffsets[i], Math.Min(sizeof(Float4), (int)source.PropertySizes[i]));
			}
			return value;
		}

		let onPhong = scope MaterialAsset();
		ModelMaterialBuild.Build(model, model.Materials[0], "m", textures, packed, onPhong);
		Test.Assert(onPhong.Source.ShaderName == "phong");
		Test.Assert(Slots(onPhong, .. scope .()) == "AlbedoMap NormalMap SpecularMap");
		Test.Assert(Math.Abs(Uniform(onPhong, "SpecularColor").Y - 0.25f) < 1e-5f);
		Test.Assert(Math.Abs(Uniform(onPhong, "Shininess").X - 32.0f) < 1e-5f);

		let onLambert = scope MaterialAsset();
		ModelMaterialBuild.Build(model, model.Materials[1], "m", textures, packed, onLambert);
		Test.Assert(onLambert.Source.ShaderName == "phong");
		Test.Assert(Slots(onLambert, .. scope .()) == "AlbedoMap NormalMap", "no highlight, so no specular map");
		Test.Assert(Uniform(onLambert, "SpecularColor").X == 0.0f);

		let onUnlit = scope MaterialAsset();
		ModelMaterialBuild.Build(model, model.Materials[2], "m", textures, packed, onUnlit);
		Test.Assert(onUnlit.Source.ShaderName == "unlit");
		Test.Assert(Slots(onUnlit, .. scope .()) == "AlbedoMap");

		let onPbr = scope MaterialAsset();
		ModelMaterialBuild.Build(model, model.Materials[3], "m", textures, packed, onPbr);
		Test.Assert(onPbr.Source.ShaderName == "forward");
		Test.Assert(Slots(onPbr, .. scope .()) == "AlbedoMap NormalMap OcclusionMap MetallicRoughnessMap");
		Test.Assert(bakes == 1, "its separate rough map baked into the packed one by the caller");
	}
}
