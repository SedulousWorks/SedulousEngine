using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.Texture;
using Sedulous.Texture.Compression;
using Sedulous.Texture.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Texture.Tests;

/// The texture editor's registration, undo snapshot, derivations and thumbnail.
class TextureEditorTests
{
	[Test]
	public static void TheFactoryReportsTheTextureAssetPrimaryType()
	{
		let factory = scope TextureEditorPageFactory();
		Test.Assert(factory.PrimaryType == typeof(TextureAsset));
	}

	[Test]
	public static void RegisteringRoutesTextureAssetToTheFactory()
	{
		let context = scope EditorContext();
		TextureEditor.Register(context);
		let found = context.Pages.FindFactory(typeof(TextureAsset));
		Test.Assert((found != null) && (found.PrimaryType == typeof(TextureAsset)));
	}

	[Test]
	public static void TheSnapshotRoundTripsEveryImportSetting()
	{
		TexturePipeline.RegisterAll();
		let original = scope TextureAsset();
		original.FileName.Set("Textures/brick.png");
		original.ColorSpace = .Linear;
		original.Shape = .Cubemap;
		original.MinFilter = .MipmapNearest;
		original.MagFilter = .Nearest;
		original.WrapU = .MirroredRepeat;
		original.WrapV = .ClampToBorder;
		original.WrapW = .ClampToEdge;
		original.GenerateMipmaps = false;
		original.Anisotropy = 8.0f;
		original.Usage = .Normal;
		original.Compression = .Quality;
		let blob = scope List<uint8>();
		TextureAssetEdit.Snapshot(original, blob);
		let restored = scope TextureAsset();
		Test.Assert(TextureAssetEdit.Apply(restored, blob));
		Test.Assert(restored.FileName.Value == "Textures/brick.png");
		Test.Assert(restored.ColorSpace == .Linear);
		Test.Assert(restored.Shape == .Cubemap);
		Test.Assert((restored.MinFilter == .MipmapNearest) && (restored.MagFilter == .Nearest));
		Test.Assert((restored.WrapU == .MirroredRepeat) && (restored.WrapV == .ClampToBorder) && (restored.WrapW == .ClampToEdge));
		Test.Assert(!restored.GenerateMipmaps);
		Test.Assert(restored.Anisotropy == 8.0f);
		Test.Assert((restored.Usage == .Normal) && (restored.Compression == .Quality));
		Test.Assert(!TextureAssetEdit.Apply(restored, blob));
	}

	[Test]
	public static void TheProfilesMoveTheSamplerSettingsAProfileButtonApplies()
	{
		let asset = scope TextureAsset();
		asset.SetupFor3D();
		Test.Assert(asset.GenerateMipmaps && (asset.Anisotropy == 16.0f) && (asset.WrapU == .Repeat));
		asset.SetupForUI();
		Test.Assert(!asset.GenerateMipmaps && (asset.WrapU == .ClampToEdge) && (asset.MinFilter == .Linear));
		asset.SetupForSprite();
		Test.Assert((asset.MinFilter == .Nearest) && (asset.MagFilter == .Nearest));
	}

	[Test]
	public static void UsageImpliesColorSpaceAndTheLintFlagsAMismatch()
	{
		Test.Assert(TextureAssetEdit.ColorSpaceFor(.Color) == .Srgb);
		Test.Assert(TextureAssetEdit.ColorSpaceFor(.Normal) == .Linear);
		Test.Assert(TextureAssetEdit.ColorSpaceFor(.Mask) == .Linear);
		Test.Assert(TextureAssetEdit.ColorSpaceFor(.HDR) == .Linear);
		Test.Assert(TextureAssetEdit.Lint(.Normal, .Srgb).StartsWith("Normal/Mask/HDR"));
		Test.Assert(TextureAssetEdit.Lint(.Normal, .Linear).IsEmpty);
		Test.Assert(TextureAssetEdit.Lint(.Color, .Srgb).IsEmpty);
		Test.Assert(TextureAssetEdit.Lint(.Color, .Linear).StartsWith("Color as Linear"));
		Test.Assert(TextureAssetEdit.MipLevels(256, 256) == 9);
		Test.Assert(TextureAssetEdit.MipLevels(1, 1) == 1);
		Test.Assert(TextureAssetEdit.MipLevels(4, 1) == 3);
	}

	[Test]
	public static void TheCooksToRowFollowsTheDesktopPolicy()
	{
		let rgba8 = TextureFormat.RGBA8Unorm;
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Color, true, true, false, .Default, 512, 512, .Desktop, rgba8) == .BC7RGBAUnormSrgb);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Color, true, true, false, .None, 512, 512, .Desktop, rgba8) == rgba8);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Normal, false, false, false, .Default, 512, 512, .Desktop, rgba8) == .BC7RGBAUnorm);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Mask, false, false, false, .Default, 512, 512, .Desktop, rgba8) == .BC4RUnorm);
		Test.Assert(TextureCompression.ResolveCompressedFormat(.Mask, false, false, true, .Default, 512, 512, .Desktop, rgba8) == .BC7RGBAUnorm);
		Test.Assert(TextureAssetEdit.CookedFormatName(.BC4RUnorm) == "BC4 (single channel)");
		Test.Assert(TextureAssetEdit.CookedFormatName(.RGBA8Unorm) == "uncompressed");

		// Without a preview the row still answers, from the asset alone.
		let asset = scope TextureAsset();
		asset.Compression = .None;
		Test.Assert(TextureAssetEdit.ResolvedFormatText(asset, null, .RGBA8, .. scope .()) == "uncompressed");
		Test.Assert(TextureAssetEdit.ResolvedFormatText(null, null, .RGBA8, .. scope .()) == "-");
	}

	[Test]
	public static void TheThumbnailLetterboxesAndChecksTranslucentTexels()
	{
		// A 64 x 32 opaque red image with a translucent right half.
		let payload = scope List<uint8>();
		TextureThumbnailGenerator.WriteRawHeader(payload, 64, 32);
		for (uint32 y < 32)
		{
			for (uint32 x < 64)
			{
				payload.Add(255); payload.Add(0); payload.Add(0);
				payload.Add((x < 32) ? 255 : 0);
			}
		}
		let generator = scope TextureThumbnailGenerator();
		let tile = scope Image();
		Test.Assert(generator.Generate(payload, tile) case .Ok);
		let size = ThumbnailService.cThumbnailSize;
		Test.Assert((tile.Width == size) && (tile.Height == size));
		let px = tile.PixelData;
		// Letterbox rows stay transparent; the fitted band's left is red, its right is checker grey.
		Test.Assert(px[3] == 0);
		let mid = (int)(size / 2) * (int)size * 4;
		Test.Assert((px[mid + 0] == 255) && (px[mid + 3] == 255));
		let right = mid + ((int)size - 1) * 4;
		Test.Assert((px[right + 3] == 255) && (px[right + 0] == px[right + 1]) && (px[right + 0] >= 128));

		// A truncated raw payload is refused.
		let bad = scope List<uint8>();
		TextureThumbnailGenerator.WriteRawHeader(bad, 64, 32);
		bad.Add(0);
		Test.Assert(generator.Generate(bad, tile) case .Err);
	}

	[Test]
	public static void HdrSourcesPreviewAsClampedRgba8()
	{
		let hdr = scope Image(2, 1, .RGBA32F);
		let f = (float*)hdr.PixelData.Ptr;
		f[0] = 2.0f; f[1] = 0.5f; f[2] = 0.0f; f[3] = 1.0f;
		f[4] = -1.0f; f[5] = 1.0f; f[6] = 0.25f; f[7] = 1.0f;
		let preview = TexturePreview.From(hdr);
		Test.Assert(preview != null);
		defer delete preview;
		let px = preview.PixelData;
		Test.Assert((px[0] == 255) && (px[1] == 128) && (px[2] == 0) && (px[3] == 255));
		Test.Assert((px[4] == 0) && (px[5] == 255) && (px[6] == 64));

		let odd = scope Image(2, 2, .R8);
		Test.Assert(TexturePreview.From(odd) == null);
	}
}
