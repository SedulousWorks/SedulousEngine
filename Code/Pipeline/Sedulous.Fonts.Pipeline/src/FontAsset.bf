using Sedulous.Core;
using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Fonts.Pipeline;

/// A font file and how it should become a cooked font.
[Category("Fonts")]
[DisplayName("Font")]
[Serializable]
class FontAsset : Asset
{
	/// The runtime family name. Empty means the bake takes the file's own.
	[DisplayName("Family")]
	public String Family = new .() ~ delete _;

	[DisplayName("Bake Mode")]
	public FontBakeMode Mode = .RasterRamp;

	/// Raster ramp: one cooked entry per size.
	public List<float> Sizes = new .() ~ delete _;

	/// Distance field: the single bake size.
	[DisplayName("Distance-Field Size")]
	[Range(8.0f, 128.0f, 1.0f)]
	[VisibleWhen("Mode=1")] // DistanceField only
	public float DistanceFieldSize = 48.0f;

	[DisplayName("First Codepoint")]
	public int32 FirstCodepoint = 32;
	/// Extended Latin by default, matching the runtime rasteriser.
	[DisplayName("Last Codepoint")]
	public int32 LastCodepoint = 255;

	[DisplayName("Atlas Width")]
	public uint32 AtlasWidth = 1024;
	[DisplayName("Atlas Height")]
	public uint32 AtlasHeight = 1024;

	public this()
	{
		SetupDefaultRamp();
	}

	/// The interface size ramp, from a field to a heading.
	public void SetupDefaultRamp()
	{
		Sizes.Clear();
		Sizes.AddRange(scope float[](10.0f, 11.0f, 12.0f, 13.0f, 14.0f, 16.0f, 18.0f, 20.0f,
			24.0f, 32.0f));
	}
}
