using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Image;
using Sedulous.Image.DDS;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.RHI;
using Sedulous.Texture.Compression;
using Sedulous.Texture.Pipeline;
using Sedulous.Texture.Resource;
using static Sedulous.RHI.TextureFormats;

namespace Sedulous.Texture.Pipeline.Tests;

/// A DDS source through the cook: its levels pass through byte for byte when they fit, and
/// decode and re-encode by the policy when they do not.
class TextureDdsCookTests
{
	/// A deterministic gradient level, which is what the encoder is fed.
	private static void GradientLevel(List<uint8> pixels, uint32 size)
	{
		pixels.Count = (int)size * (int)size * 4;
		for (uint32 y < size)
		{
			for (uint32 x < size)
			{
				let p = &pixels[((int)y * (int)size + (int)x) * 4];
				p[0] = (uint8)((x * 255) / Math.Max(size - 1, 1));
				p[1] = (uint8)((y * 255) / Math.Max(size - 1, 1));
				p[2] = 128;
				p[3] = 255;
			}
		}
	}

	/// A DDS whose every level is that gradient, encoded by the engine's own encoder.
	private static void EncodedDds(DdsImage outImage, uint32 size, uint32 levels,
		TextureFormat blockFormat, DdsFormat ddsFormat)
	{
		outImage.Width = size;
		outImage.Height = size;
		outImage.MipLevels = levels;
		outImage.Format = ddsFormat;
		outImage.ColorSpaceKnown = true;

		var w = size;
		let pixels = scope List<uint8>();
		let blocks = scope List<uint8>();
		for (uint32 level < levels)
		{
			GradientLevel(pixels, w);
			blocks.Clear();
			TextureCompression.EncodeBlockCompressed(pixels.Ptr, w, w, blockFormat, 128, blocks);
			Test.Assert((uint64)blocks.Count == CompressedLevelBytes(blockFormat, w, w));
			outImage.Data.AddRange(blocks);
			w = (w > 1) ? (w / 2) : 1;
		}
		Test.Assert(outImage.Data.Count == outImage.LayerSize());
	}

	private static void WriteDdsFile(TexturePipelineFixture fixture, DdsImage image,
		StringView fileName)
	{
		let bytes = scope List<uint8>();
		Test.Assert(Dds.WriteDds(image, bytes) case .Ok);

		let path = scope String();
		fixture.PathIn(fileName, path);
		let stream = scope System.IO.FileStream();
		Test.Assert(stream.Create(path) case .Ok);
		Test.Assert(stream.TryWrite(bytes) case .Ok);
		stream.Close();
	}

	/// Cooks a file backed asset against a target, reading back the record and the payload.
	private static Result<void, ErrorCode> CookFile(TexturePipelineFixture fixture,
		TextureAsset asset, CookTarget target, TextureResource outRecord, List<uint8> outPayload)
	{
		let output = fixture.CreateOutput(
			scope $"out_{fixture.Database.RootGroup.Instances.Count}");
		fixture.Context.Source = null;
		fixture.Context.Output = output;
		fixture.Context.Target = target;

		if (scope TextureAssetBuilder().Build(asset, fixture.Context) case .Err(let error))
			return .Err(error);
		return fixture.ReadCooked(output, outRecord, outPayload);
	}

	[Test]
	public static void ABc7DdsWithItsMipChainPassesThroughByteForByte()
	{
		let fixture = scope TexturePipelineFixture("dds_bc7");

		let source = scope DdsImage();
		EncodedDds(source, 8, 4, .BC7RGBAUnorm, .BC7Srgb);
		WriteDdsFile(fixture, source, "bc7.dds");

		let asset = scope TextureAsset();
		asset.FileName.Set("bc7.dds");
		asset.SetupFor3D(); // colour, sRGB, mips

		let record = scope TextureResource();
		let payload = scope List<uint8>();
		Test.Assert(CookFile(fixture, asset, .Host, record, payload) case .Ok);
		Test.Assert(record.Format == .BC7RGBAUnormSrgb);
		Test.Assert(record.Width == 8);
		Test.Assert(record.MipLevels == 4);
		Test.Assert(payload.Count == source.Data.Count);
		Test.Assert(Internal.MemCmp(payload.Ptr, source.Data.Ptr, payload.Count) == 0,
			"the package's own bytes, unencoded");

		// The ASSET's colour space picks the format twin: the same bytes, the linear view.
		asset.ColorSpace = .Linear;
		Test.Assert(CookFile(fixture, asset, .Host, record, payload) case .Ok);
		Test.Assert(record.Format == .BC7RGBAUnorm);
		Test.Assert(payload.Count == source.Data.Count);

		// No mips asked for, which is the interface preset: level nought alone passes through.
		asset.SetupForUI();
		Test.Assert(CookFile(fixture, asset, .Host, record, payload) case .Ok);
		Test.Assert(record.MipLevels == 1);
		Test.Assert(payload.Count == source.LevelSize(0));
		Test.Assert(record.Format == .BC7RGBAUnormSrgb);

		// Compression None is the escape hatch: the blocks decode and cook raw, with mips.
		asset.SetupFor3D();
		asset.Compression = .None;
		Test.Assert(CookFile(fixture, asset, .Host, record, payload) case .Ok);
		Test.Assert(record.Format == .RGBA8UnormSrgb);
		Test.Assert(record.MipLevels == 4);
		Test.Assert(payload.Count == ((64 + 16 + 4 + 1) * 4));
	}

	[Test]
	public static void ABc5NormalMapDdsDecodesAndReEncodesByThePolicy()
	{
		let fixture = scope TexturePipelineFixture("dds_bc5");

		// A flat normal at 128 pixels, which clears the policy's small texture cutoff, with no
		// mip chain: a package normal map as they usually arrive.
		let source = scope DdsImage();
		source.Width = 128;
		source.Height = 128;
		source.MipLevels = 1;
		source.Format = .BC5;
		source.ColorSpaceKnown = true;
		{
			let flat = scope List<uint8>();
			flat.Count = 128 * 128 * 4;
			for (int i < 128 * 128)
			{
				flat[i * 4 + 0] = 128;
				flat[i * 4 + 1] = 128;
				flat[i * 4 + 2] = 255;
				flat[i * 4 + 3] = 255;
			}
			let blocks = scope List<uint8>();
			TextureCompression.EncodeBlockCompressed(flat.Ptr, 128, 128, .BC5RGUnorm, 128, blocks);
			Test.Assert((uint64)blocks.Count == CompressedLevelBytes(.BC5RGUnorm, 128, 128));
			source.Data.AddRange(blocks);
		}
		WriteDdsFile(fixture, source, "bc5.dds");

		let asset = scope TextureAsset();
		asset.FileName.Set("bc5.dds");
		asset.SetupForNormalMap();

		let record = scope TextureResource();
		let payload = scope List<uint8>();
		Test.Assert(CookFile(fixture, asset, .Host, record, payload) case .Ok);
		// Never BC5: the shaders read a whole normal, so the cooked format carries three.
		Test.Assert(record.Format == .BC7RGBAUnorm);
		Test.Assert(record.MipLevels == 8, "128 down to one");

		var expected = (uint64)0;
		var w = (uint32)128;
		for (uint32 level < 8)
		{
			expected += CompressedLevelBytes(.BC7RGBAUnorm, w, w);
			w = (w > 1) ? (w / 2) : 1;
		}
		Test.Assert((uint64)payload.Count == expected);
	}

	[Test]
	public static void AnAstcTargetDecodesABcDdsAndACubemapIsRefused()
	{
		let fixture = scope TexturePipelineFixture("dds_astc");

		let source = scope DdsImage();
		EncodedDds(source, 128, 1, .BC1RGBAUnorm, .BC1Srgb);
		WriteDdsFile(fixture, source, "bc1.dds");

		let asset = scope TextureAsset();
		asset.FileName.Set("bc1.dds");
		asset.SetupFor3D();

		let record = scope TextureResource();
		let payload = scope List<uint8>();
		// A target that reads ASTC and not BC: the blocks cannot pass through, so they decode
		// and re-encode.
		let mobile = CookTarget("web-astc", false, true, false);
		Test.Assert(CookFile(fixture, asset, mobile, record, payload) case .Ok);
		Test.Assert(record.Format == .ASTC4x4UnormSrgb);
		Test.Assert(record.MipLevels == 8);

		// A cubemap DDS is refused rather than cooked wrong: only two dimensional sources cook.
		let cube = scope DdsImage();
		EncodedDds(cube, 4, 1, .BC1RGBAUnorm, .BC1);
		cube.Cubemap = true;
		cube.ArrayLayers = 6;
		let face = scope List<uint8>();
		face.AddRange(cube.Data);
		for (uint32 f = 1; f < 6; f++)
			cube.Data.AddRange(face);
		WriteDdsFile(fixture, cube, "cube.dds");

		asset.FileName.Set("cube.dds");
		Test.Assert(CookFile(fixture, asset, .Host, record, payload) case .Err(.NotSupported));
	}

	/// A DDS imports with the facts its OWN header names: the block format says what the file
	/// holds, and a DX10 header settles the colour space.
	[Test]
	public static void ADdsImportsWithTheFactsItsHeaderNames()
	{
		let fixture = scope TexturePipelineFixture("dds_import");
		let importer = scope TextureFileImporter();
		Test.Assert(importer.Accepts("dds"));

		TextureAsset ImportOne(StringView fileName)
		{
			let loose = scope:: String();
			fixture.PathIn(fileName, loose);
			let context = scope:: ImportContext(fixture.Root);
			let instance = importer.Import(loose, context, fixture.Database.RootGroup, null, null,
				null);
			Test.Assert(instance case .Ok);
			let object = instance.Value.ReadObject();
			let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as TextureAsset;
			Test.Assert(asset != null);
			return asset;
		}

		// BC5 is a normal map, whatever the name happens to say.
		let normal = scope DdsImage();
		EncodedDds(normal, 4, 1, .BC5RGUnorm, .BC5);
		WriteDdsFile(fixture, normal, "thing.dds");
		{
			let asset = ImportOne("thing.dds");
			defer delete asset;
			Test.Assert(asset.Usage == .Normal);
			Test.Assert(asset.ColorSpace == .Linear);
			Test.Assert(asset.FileName.Value == "thing.dds");
		}

		// BC4 is a data mask.
		let mask = scope DdsImage();
		EncodedDds(mask, 4, 1, .BC4RUnorm, .BC4);
		WriteDdsFile(fixture, mask, "stuff.dds");
		{
			let asset = ImportOne("stuff.dds");
			defer delete asset;
			Test.Assert(asset.Usage == .Mask);
		}

		// And a DX10 colour format settles the colour space either way.
		let linear = scope DdsImage();
		EncodedDds(linear, 4, 1, .BC7RGBAUnorm, .BC7);
		WriteDdsFile(fixture, linear, "wall.dds");
		{
			let asset = ImportOne("wall.dds");
			defer delete asset;
			Test.Assert(asset.Usage == .Color);
			Test.Assert(asset.ColorSpace == .Linear);
			Test.Assert(asset.GenerateMipmaps, "the surface preset");
		}

		let srgb = scope DdsImage();
		EncodedDds(srgb, 4, 1, .BC1RGBAUnorm, .BC1Srgb);
		WriteDdsFile(fixture, srgb, "brick.dds");
		{
			let asset = ImportOne("brick.dds");
			defer delete asset;
			Test.Assert(asset.ColorSpace == .Srgb);
		}
	}
}
