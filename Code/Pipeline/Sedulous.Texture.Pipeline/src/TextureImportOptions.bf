using System;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Pipeline.Importer;
using Sedulous.Texture;
using Sedulous.Texture.Compression;

namespace Sedulous.Texture.Pipeline;

/// A texture import's settings, which the import window draws: what the texture is used for, its
/// colour space, compression, wrap and mipmaps. They start as the importer chooses for the file
/// (TextureFileImporter.InitializeOptions), the usage guessed from its name.
[Reflect(.NonStaticFields | .DefaultConstructor)]
class TextureImportOptions : ImportOptions
{
	[DisplayName("Usage"), Description("What it is: a colour map, a normal map, a data mask (roughness, AO, height) or an HDR environment; sets its sampler as the texture page's profiles do")]
	public SourceUsage Usage = .Color;
	[DisplayName("Colour space"), Description("sRGB for a colour map; linear for data (normals, masks) and HDR")]
	public ImageColorSpace ColorSpace = .Srgb;
	[DisplayName("Compression"), Description("Default picks by usage and platform; None keeps every pixel; Quality spends more time for a better result")]
	public CompressionChoice Compression = .Default;
	/// Both U and V.
	[DisplayName("Wrap"), Description("What lies past its edges, across and down: repeat it, or clamp to the edge")]
	public TextureWrap Wrap = .Repeat;
	[DisplayName("Mipmaps"), Description("Smaller copies for when it is drawn small, which keep it from shimmering")]
	public bool GenerateMipmaps = true;

	/// Takes the settings `asset` was set up with (a preset).
	public void From(TextureAsset asset)
	{
		Usage = asset.Usage;
		ColorSpace = asset.ColorSpace;
		Compression = asset.Compression;
		Wrap = asset.WrapU;
		GenerateMipmaps = asset.GenerateMipmaps;
	}

	/// Sets `asset` up as `chosen`'s profile does (its sampler, colour space, wrap and mipmaps).
	public static void SetupForUsage(TextureAsset asset, SourceUsage chosen)
	{
		switch (chosen)
		{
		case .Normal:
			asset.SetupForNormalMap();
		case .Mask:
			asset.SetupForDataMask();
		case .HDR:
			asset.SetupForEquirectangularSkybox();
		default:
			asset.SetupFor3D();
		}
	}

	/// Sets `asset` up for the usage chosen (its sampler and the like, as the profiles do), then
	/// gives it these settings.
	public void ApplyTo(TextureAsset asset)
	{
		SetupForUsage(asset, Usage);
		asset.ColorSpace = ColorSpace;
		asset.Compression = Compression;
		asset.WrapU = Wrap;
		asset.WrapV = Wrap;
		asset.GenerateMipmaps = GenerateMipmaps;
	}
}
