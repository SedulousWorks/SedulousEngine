using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Materials.Pipeline;
using Sedulous.Materials.Resource;
using Sedulous.Model;
using Sedulous.Texture.Pipeline;

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

	// Each material made on the built-in its shading model names, as its file authored it, by the
	// one function both cooks make materials with. Glass (transmission) draws blended.
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
		Test.Assert(onPbr.Source.BlendMode == .Opaque);

		// Glass (transmission): the engine does not refract, so it draws blended, as see-through
		// as it transmits, down to the opacity a pane keeps. A masked one stays masked.
		let glass = Add(.Pbr);
		glass.Transmission = 1.0f;
		let onGlass = scope MaterialAsset();
		ModelMaterialBuild.Build(model, glass, "m", textures, packed, onGlass);
		Test.Assert(onGlass.Source.BlendMode == .AlphaBlend);
		Test.Assert(Math.Abs(Uniform(onGlass, "BaseColor").W - ModelMaterialBuild.cTransmissiveMinOpacity) < 1e-5f);
		glass.Transmission = 0.5f;
		let halfGlass = scope MaterialAsset();
		ModelMaterialBuild.Build(model, glass, "m", textures, packed, halfGlass);
		Test.Assert(Math.Abs(Uniform(halfGlass, "BaseColor").W - (1.0f - 0.5f * (1.0f - ModelMaterialBuild.cTransmissiveMinOpacity))) < 1e-5f);
		glass.AlphaMode = .Mask;
		let maskedGlass = scope MaterialAsset();
		ModelMaterialBuild.Build(model, glass, "m", textures, packed, maskedGlass);
		Test.Assert(maskedGlass.Source.BlendMode == .Masked);
		Test.Assert(Math.Abs(Uniform(maskedGlass, "BaseColor").W - 1.0f) < 1e-5f);
	}

	/// One texture, as the base colour of leaves tested at 0.5, leaves tested at 0.3, and a veil
	/// blending with it.
	private const String cShrub = """
{"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"mesh":0}],"meshes":[{"primitives":[{"attributes":{"POSITION":0,"TEXCOORD_0":1},"material":0},{"attributes":{"POSITION":0,"TEXCOORD_0":1},"material":1},{"attributes":{"POSITION":0,"TEXCOORD_0":1},"material":2}]}],"materials":[{"name":"LeavesHalf","alphaMode":"MASK","alphaCutoff":0.5,"pbrMetallicRoughness":{"baseColorTexture":{"index":0}}},{"name":"LeavesLow","alphaMode":"MASK","alphaCutoff":0.3,"pbrMetallicRoughness":{"baseColorTexture":{"index":0}}},{"name":"Veil","alphaMode":"BLEND","pbrMetallicRoughness":{"baseColorTexture":{"index":0}}}],"textures":[{"source":0}],"images":[{"name":"leaf","uri":"leaf.png"}],"buffers":[{"byteLength":60,"uri":"data:application/octet-stream;base64,AAAAAAAAAAAAAAAAAACAPwAAAAAAAAAAAAAAAAAAgD8AAAAAAAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/"}],"bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":36},{"buffer":0,"byteOffset":36,"byteLength":24}],"accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3","min":[0,0,0],"max":[1,1,0]},{"bufferView":1,"componentType":5126,"count":3,"type":"VEC2"}]}
""";

	/// A base colour shared by materials with different alpha uses is an asset per use: each
	/// tested material reads a copy keeping its own cutoff's coverage, the veil the alpha as
	/// authored.
	[Test]
	public static void ABaseColourSharedByMaterialsWithDifferentAlphaUsesIsAnAssetPerUse()
	{
		let fixture = scope ImportFixture("scratch_gltf_alphauses");
		let dropped = scope String();
		fixture.WriteDroppedFile("Shrub.gltf", cShrub, dropped);
		// A 2 x 2 RGBA image, two texels opaque and two clear, beside the model.
		uint8[?] leaf = .(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02, 0x08, 0x06, 0x00, 0x00, 0x00, 0x72, 0xb6, 0x0d, 0x24, 0x00, 0x00, 0x00, 0x11, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0xf8, 0x0f, 0x01, 0x0c, 0x0c, 0x20, 0x02, 0xc4, 0x02, 0x00, 0x80, 0x91, 0x0d, 0xf3, 0x7e, 0xc1, 0xff, 0xde, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82);
		let leafPath = scope String();
		fixture.SubPath("leaf.png", leafPath);
		Test.Assert(WriteFile(leafPath, .(&leaf[0], leaf.Count)) case .Ok);

		let importer = scope ModelFileImporter();
		let imported = importer.Import(dropped, fixture.Context, fixture.RootGroup, null, null, null);
		Test.Assert(imported case .Ok(let instance));
		let manifest = ImportFixture.ReadManifest(instance);
		defer delete manifest;
		Test.Assert(manifest.Manifest.MaterialGuid.Count == 3);
		var textures = 0;
		for (let each in instance.OwningGroup.Instances)
			textures += (each.TypeName == "Sedulous.Texture.Pipeline.TextureAsset") ? 1 : 0;
		Test.Assert(textures == 3, "the texture, and a copy for each cutoff");

		// The texture each material reads as its base colour, and what that asset keeps.
		void BaseColour(int material, out bool coverage, out float reference, String outName, out Guid id)
		{
			let materialInstance = fixture.Db.GetInstance(manifest.Manifest.MaterialGuid[material]);
			Test.Assert(materialInstance != null);
			let owned = scope List<Object>();
			defer { ClearAndDeleteItems(owned); }
			let materialObject = materialInstance.ReadObject();
			owned.Add(materialObject);
			let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(materialObject)) as MaterialAsset;
			Test.Assert(asset != null);
			id = SlotId(asset.Source, "AlbedoMap");
			let texture = fixture.Db.GetInstance(id);
			Test.Assert(texture != null);
			outName.Set(texture.Name);
			let textureObject = texture.ReadObject();
			owned.Add(textureObject);
			let textureAsset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(textureObject)) as TextureAsset;
			Test.Assert(textureAsset != null);
			coverage = textureAsset.PreserveAlphaCoverage;
			reference = textureAsset.AlphaCoverageReference;
			Test.Assert(manifest.Manifest.MaterialAlbedo[material] == id, "the manifest names the same one");
		}
		let halfName = scope String();
		let lowName = scope String();
		let veilName = scope String();
		BaseColour(0, let halfCoverage, let halfReference, halfName, let halfId);
		BaseColour(1, let lowCoverage, let lowReference, lowName, let lowId);
		BaseColour(2, let veilCoverage, let veilReference, veilName, let veilId);
		Test.Assert(!veilCoverage, scope String()..AppendF("the alpha as authored, not kept at {}", veilReference));
		Test.Assert(halfCoverage && (Math.Abs(halfReference - 0.5f) < 0.01f));
		Test.Assert(lowCoverage && (Math.Abs(lowReference - 0.3f) < 0.01f));
		Test.Assert((halfId != lowId) && (halfId != veilId));
		Test.Assert(halfName.StartsWith(veilName) && lowName.StartsWith(veilName), "a copy is named after the texture");
	}
}
