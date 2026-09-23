using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Image;
using Sedulous.Image.DDS;
using Sedulous.Model;
using Sedulous.Pipeline.Cook;
using Sedulous.RHI;
using Sedulous.Texture.Pipeline;
using Sedulous.Texture.Resource;

namespace Sedulous.ModelImporter.Tests;

/// A model whose textures are GPU ready containers: the loader leaves them ON DISK, the
/// import makes file backed assets at the model relative path, and the cook passes the block
/// compressed levels through rather than decoding and re-encoding them.
///
/// The document's shape is a Lumberyard export's: specular glossiness materials, and textures
/// whose `source` names a PNG with the DDS under MSFT_texture_dds.
class ModelDdsImportTests
{
	private const String cDocument = """
{"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"mesh":0,"name":"Tri"}],"meshes":[{"primitives":[{"attributes":{"POSITION":0,"NORMAL":1,"TEXCOORD_0":2},"indices":3,"material":0}]}],"extensionsUsed":["KHR_materials_pbrSpecularGlossiness","MSFT_texture_dds"],"materials":[{"name":"Mat","extensions":{"KHR_materials_pbrSpecularGlossiness":{"diffuseTexture":{"index":0},"glossinessFactor":0.25}},"normalTexture":{"index":1}}],"textures":[{"source":2,"extensions":{"MSFT_texture_dds":{"source":0}}},{"source":3,"extensions":{"MSFT_texture_dds":{"source":1}}}],"images":[{"uri":"tex/albedo.dds"},{"uri":"tex/normal.dds"},{"uri":"tex/albedo.png"},{"uri":"tex/normal.png"}],"buffers":[{"uri":"tri.bin","byteLength":102}],"bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":36},{"buffer":0,"byteOffset":36,"byteLength":36},{"buffer":0,"byteOffset":72,"byteLength":24},{"buffer":0,"byteOffset":96,"byteLength":6}],"accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3","min":[0,0,0],"max":[1,1,0]},{"bufferView":1,"componentType":5126,"count":3,"type":"VEC3"},{"bufferView":2,"componentType":5126,"count":3,"type":"VEC2"},{"bufferView":3,"componentType":5123,"count":3,"type":"SCALAR"}]}
""";

	private static void PutF32(List<uint8> outBytes, float value)
	{
		var v = value;
		let p = (uint8*)&v;
		for (int i < 4)
			outBytes.Add(p[i]);
	}

	private static void PutU16(List<uint8> outBytes, uint16 value)
	{
		outBytes.Add((uint8)(value & 0xFF));
		outBytes.Add((uint8)(value >> 8));
	}

	/// A solid BC1 block: one endpoint repeated with every index nought.
	private static void Bc1Solid(List<uint8> outBytes, uint16 rgb565)
	{
		for (int i < 2)
		{
			outBytes.Add((uint8)(rgb565 & 0xFF));
			outBytes.Add((uint8)(rgb565 >> 8));
		}
		for (int i < 4)
			outBytes.Add(0);
	}

	private static void Bc4Solid(List<uint8> outBytes, uint8 value)
	{
		outBytes.Add(value);
		outBytes.Add(value);
		for (int i < 6)
			outBytes.Add(0);
	}

	private static void WriteDdsFile(DdsImage image, StringView path)
	{
		let bytes = scope List<uint8>();
		Test.Assert(Dds.WriteDds(image, bytes) case .Ok);
		Test.Assert(WriteFile(path, bytes) case .Ok);
	}

	/// A one triangle glTF whose material binds a BC1 sRGB albedo with three levels in the
	/// base colour slot and a BC5 normal with one level in the normal slot.
	private static void WriteDdsTriangle(ImportFixture fixture, String outDropped)
	{
		let bin = scope List<uint8>();
		float[9] positions = .(0, 0, 0, 1, 0, 0, 0, 1, 0);
		float[9] normals = .(0, 0, 1, 0, 0, 1, 0, 0, 1);
		float[6] uvs = .(0, 0, 1, 0, 0, 1);
		for (let v in positions)
			PutF32(bin, v);
		for (let v in normals)
			PutF32(bin, v);
		for (let v in uvs)
			PutF32(bin, v);
		PutU16(bin, 0);
		PutU16(bin, 1);
		PutU16(bin, 2);
		Test.Assert(bin.Count == 102);

		fixture.WriteDroppedFile("tri.gltf", cDocument, outDropped);
		let binPath = scope String();
		fixture.SubPath("tri.bin", binPath);
		Test.Assert(WriteFile(binPath, bin) case .Ok);

		let texDir = scope String();
		fixture.SubPath("tex", texDir);
		CreateDirectory(texDir);

		let albedo = scope DdsImage();
		albedo.Width = 4;
		albedo.Height = 4;
		albedo.MipLevels = 3;
		albedo.Format = .BC1Srgb;
		albedo.ColorSpaceKnown = true;
		for (int level < 3)
			Bc1Solid(albedo.Data, 0xF800);
		let albedoPath = scope String();
		fixture.SubPath("tex/albedo.dds", albedoPath);
		WriteDdsFile(albedo, albedoPath);

		let normal = scope DdsImage();
		normal.Width = 4;
		normal.Height = 4;
		normal.MipLevels = 1;
		normal.Format = .BC5;
		normal.ColorSpaceKnown = true;
		Bc4Solid(normal.Data, 128);
		Bc4Solid(normal.Data, 128);
		let normalPath = scope String();
		fixture.SubPath("tex/normal.dds", normalPath);
		WriteDdsFile(normal, normalPath);
	}

	private static TextureAsset ReadTextureAsset(Instance instance)
	{
		let object = instance.ReadObject();
		return Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as TextureAsset;
	}

	private static TextureResource ReadCookedTexture(ImportFixture fixture, Guid id)
	{
		let object = fixture.CookedDb.ReadObject(id);
		return Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as TextureResource;
	}

	[Test]
	public static void DdsTexturesStayOnDiskAsFileBackedAssetsAndPassThroughTheCook()
	{
		let fixture = scope ImportFixture("scratch_dds_model");
		let dropped = scope String();
		WriteDdsTriangle(fixture, dropped);

		// The loader leaves both files undecoded and remembers where they are, and it takes
		// the DDS the extension names rather than the PNG the `source` does.
		{
			let loaded = scope Model();
			Test.Assert(ModelFileLoad.Load(dropped, loaded) == .Ok);
			Test.Assert(loaded.Textures.Length == 2);
			Test.Assert(loaded.Textures[0].Data.IsEmpty);
			Test.Assert(!loaded.Textures[0].SourceFile.IsEmpty);
			Test.Assert(loaded.Textures[1].Uri == "tex/normal.dds", "the DDS, not the PNG");

			Test.Assert(loaded.Materials.Length == 1);
			let material = loaded.Materials[0];
			// The specular glossiness diffuse stands in for the base colour.
			Test.Assert(material.BaseColorTextureIndex == 0);
			Test.Assert(material.NormalTextureIndex == 1);
			Test.Assert(Math.Abs(material.RoughnessFactor - 0.75f) < 0.001f);
			Test.Assert(Math.Abs(material.MetallicFactor) < 0.001f);
		}

		let importer = scope ModelFileImporter();
		let imported = importer.Import(dropped, fixture.Context, fixture.RootGroup, null, null,
			null);
		Test.Assert(imported case .Ok);

		// ONE copy each, at the model relative path the sidecar pass uses, never a second flat
		// copy beside it.
		for (let relative in scope String[]("Sources/tex/albedo.dds", "Sources/tex/normal.dds"))
		{
			let path = scope String();
			fixture.SubPath(relative, path);
			Test.Assert(FileExists(path), relative);
		}
		let flat = scope String();
		fixture.SubPath("Sources/albedo.dds", flat);
		Test.Assert(!FileExists(flat), "the sidecar pass already placed it");

		let modelGroup = fixture.RootGroup.GetGroup("tri");
		Test.Assert(modelGroup != null);
		let albedoInstance = modelGroup.GetInstance("albedo");
		let normalInstance = modelGroup.GetInstance("normal");
		Test.Assert((albedoInstance != null) && (normalInstance != null));

		{
			let asset = ReadTextureAsset(albedoInstance);
			defer delete asset;
			Test.Assert(asset != null);
			Test.Assert(asset.FileName.Value == "tex/albedo.dds", "file backed, not embedded");
			Test.Assert(asset.EmbeddedWidth == 0);
			Test.Assert(asset.Usage == .Color);
			Test.Assert(asset.ColorSpace == .Srgb, "the DX10 header's own fact");
			Test.Assert(asset.SourceHint == "tex/albedo.dds");
		}
		{
			let asset = ReadTextureAsset(normalInstance);
			defer delete asset;
			Test.Assert(asset != null);
			Test.Assert(asset.FileName.Value == "tex/normal.dds");
			Test.Assert(asset.Usage == .Normal, "the material slot says so");
			Test.Assert(asset.ColorSpace == .Linear);
		}

		// Through the cook: the albedo's BC1 chain passes through untouched, and the BC5
		// normal decodes, the shaders reading a whole normal, and cooks by policy, which for
		// something this small is raw RGBA8 with generated mips.
		let driver = scope CookDriver(fixture.Db, fixture.CookedDb, fixture.Builders,
			fixture.SourcesFs, fixture.CacheFs);
		let plan = scope CookPlan();
		driver.Plan(plan);
		let stats = scope CookStats();
		driver.Execute(plan, stats);
		Test.Assert(stats.Failed == 0, scope $"{stats.Failed} failed");

		{
			let cooked = ReadCookedTexture(fixture, albedoInstance.Id);
			defer delete cooked;
			Test.Assert(cooked != null);
			Test.Assert(cooked.Format == .BC1RGBAUnormSrgb);
			Test.Assert(cooked.MipLevels == 3);
		}
		{
			let cooked = ReadCookedTexture(fixture, normalInstance.Id);
			defer delete cooked;
			Test.Assert(cooked != null);
			Test.Assert(cooked.Format == .RGBA8Unorm);
			Test.Assert(cooked.MipLevels == 3);
		}
	}
}
