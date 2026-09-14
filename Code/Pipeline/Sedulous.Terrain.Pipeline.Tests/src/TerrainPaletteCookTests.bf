using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Pipeline.Core;
using Sedulous.Terrain.Resource;
using Sedulous.Texture.Pipeline;
using Sedulous.VFS;

namespace Sedulous.Terrain.Pipeline.Tests;

/// Baking the palette array, and the image work under it.
class TerrainPaletteCookTests
{
	private const String cImageRoot = "scratch_terrain_palette_img";
	private const String cSourceRoot = "scratch_terrain_palette_src";
	private const String cCookedRoot = "scratch_terrain_palette_out";

	private static void MakeRoots()
	{
		for (let root in scope String[](cImageRoot, cSourceRoot, cCookedRoot))
		{
			RemoveDirectoryRecursive(root);
			CreateDirectory(root);
		}
		TerrainPipeline.RegisterAll();
		TerrainResources.RegisterAll();
		TexturePipeline.RegisterAll();
	}

	private static void RemoveRoots()
	{
		for (let root in scope String[](cImageRoot, cSourceRoot, cCookedRoot))
			RemoveDirectoryRecursive(root);
	}

	/// The palette cook decodes its albedos through the SOURCE database.
	///
	/// The production shape has two: the cooked view, whose texture instances hold PRODUCTS,
	/// and the source view, where the authoring envelopes and their files live. Resolving an
	/// albedo against the cooked one casts to the wrong type and silently whites out every
	/// slice, which is what a terrain painted entirely white turned out to be.
	[Test]
	public static void ThePaletteCookDecodesThroughTheSourceDatabase()
	{
		MakeRoots();
		defer { RemoveRoots(); }

		// A solid ORANGE source, because white is what the failure produces.
		{
			let authored = scope Image(8, 8, .RGBA8);
			let pixels = authored.PixelData;
			for (int t < 64)
			{
				pixels[t * 4 + 0] = 200;
				pixels[t * 4 + 1] = 120;
				pixels[t * 4 + 2] = 30;
				pixels[t * 4 + 3] = 255;
			}
			let path = scope String();
			PathJoin(cImageRoot, "albedo.png", path);
			Test.Assert(ImageIO.SaveImage(authored, path, .PNG) case .Ok);
		}

		let imageMount = scope NativeFileSystem(cImageRoot);
		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid terrainId;
		{
			let sourceDb = scope ContentDatabase(sourceMount, serializers, "xasset");
			let albedoInstance = sourceDb.RootGroup.CreateInstance("albedo",
				"Sedulous.Texture.Pipeline.TextureAsset");
			Test.Assert(albedoInstance != null);
			{
				let textureAsset = scope TextureAsset();
				textureAsset.FileName.Set("albedo.png");
				Test.Assert(albedoInstance.WriteObject(textureAsset) case .Ok);
			}

			// The COOKED view carries no authoring envelope for that id, which is the truth in
			// production and the reason the cook has to reach through the source view.
			let cookedDb = scope ContentDatabase(cookedMount, serializers, "rasset");
			let product = cookedDb.RootGroup.CreateInstance("terrain",
				"Sedulous.Terrain.Resource.TerrainSource");
			Test.Assert(product != null);
			terrainId = product.Id;

			let asset = scope TerrainAsset();
			asset.PaletteAlbedoIds.Add(albedoInstance.Id);
			asset.PaletteTileScales.Add(4.0f);
			asset.PaletteTextureSize = 64;

			let context = scope AssetBuildContext();
			context.Sources = imageMount;
			context.Output = product;
			context.Database = cookedDb;
			context.SourceDatabase = sourceDb;
			Test.Assert(scope TerrainAssetBuilder().Build(asset, context) case .Ok);
		}

		let cookedDb = scope ContentDatabase(cookedMount, serializers, "rasset");
		let instance = cookedDb.GetInstance(terrainId);
		Test.Assert(instance != null);

		let stream = instance.ReadData(TerrainPaletteData.AlbedoStream);
		Test.Assert(stream != null);
		defer delete stream;

		uint32[3] header = .();
		Test.Assert(stream.Read(.((uint8*)&header, sizeof(uint32[3]))) == sizeof(uint32[3]));
		Test.Assert(header[2] == 1); // one slice

		let bytes = TerrainPaletteData.SliceBytes(header[0], header[1]);
		let texels = scope List<uint8>();
		texels.Count = bytes;
		Test.Assert(stream.Read(texels) == bytes);

		Test.Assert(texels[0] == 200); // the authored orange, not the white fallback
		Test.Assert(texels[1] == 120);
		Test.Assert(texels[2] == 30);
		// And the one by one tail mip carries it too, so no level was left unfilled.
		let lastTexel = bytes - 4;
		Test.Assert(texels[lastTexel + 0] == 200);
		Test.Assert(texels[lastTexel + 1] == 120);
	}

	/// The per slice helpers: a solid colour survives a resize and a halving exactly, and the
	/// byte count covers the whole chain.
	[Test]
	public static void TheSliceHelpersResizeAndMip()
	{
		let red = scope List<uint8>();
		red.Count = 8 * 8 * 4;
		for (int i < 64)
		{
			red[i * 4 + 0] = 200;
			red[i * 4 + 1] = 10;
			red[i * 4 + 2] = 10;
			red[i * 4 + 3] = 255;
		}

		let resized = scope List<uint8>();
		resized.Count = 4 * 4 * 4;
		TerrainImageOps.ResizeRgba8Bilinear(red, 8, 8, resized, 4, 4);
		Test.Assert(resized[0] == 200);
		Test.Assert(resized[1] == 10);
		Test.Assert(resized[63] == 255);

		let mip = scope List<uint8>();
		mip.Count = 2 * 2 * 4;
		Test.Assert(TerrainImageOps.BoxHalveRgba8(resized, 4, mip) == 2);
		Test.Assert(mip[0] == 200); // the box filter of a solid is the solid
		Test.Assert(mip[3] == 255);

		// Four by four plus two by two plus one by one, at four bytes a texel.
		Test.Assert(TerrainPaletteData.SliceBytes(4, 3) == (16 + 4 + 1) * 4);
	}

	/// Albedo mips average in LINEAR space and re-encode.
	///
	/// Averaging the encoded bytes of a black and white checker gives a mip that is visibly too
	/// dark. The albedo array uploads as sRGB, so its mips have to take the same care the
	/// texture cook does; the plain filter stays correct for the linear data maps beside it.
	[Test]
	public static void TheAlbedoHalveAveragesInLinearSpace()
	{
		let checker = scope List<uint8>();
		checker.Count = 2 * 2 * 4;
		for (int t < 4)
			checker[t * 4 + 3] = 255;
		for (let t in scope int[](0, 3)) // the diagonal is white, the rest black
		{
			checker[t * 4 + 0] = 255;
			checker[t * 4 + 1] = 255;
			checker[t * 4 + 2] = 255;
		}

		let srgbMip = scope List<uint8>();
		srgbMip.Count = 4;
		Test.Assert(TerrainImageOps.BoxHalveRgba8SrgbAware(checker, 2, srgbMip) == 1);
		Test.Assert(srgbMip[0] >= 186); // half the light, encoded, is about 188
		Test.Assert(srgbMip[0] <= 190);
		Test.Assert(srgbMip[3] == 255); // alpha is already linear, so a plain average

		let plainMip = scope List<uint8>();
		plainMip.Count = 4;
		Test.Assert(TerrainImageOps.BoxHalveRgba8(checker, 2, plainMip) == 1);
		Test.Assert(plainMip[0] == 128);
	}
}
