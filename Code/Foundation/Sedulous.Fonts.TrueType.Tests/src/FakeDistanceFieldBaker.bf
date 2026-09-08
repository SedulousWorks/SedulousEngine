using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;

namespace Sedulous.Fonts.TrueType.Tests;

/// A stand in for the MSDF baker, so the service's distance field behaviour can be tested
/// without the real one.
///
/// The real baker lives in another module, and a unit test project takes exactly one module
/// under test. What matters here is only that the atlas SAYS it is a distance field, which
/// is what the service branches on.
class FakeDistanceFieldAtlas : IFontAtlas
{
	private uint8[16] mPixels = default;

	public override uint32 Width => 2;
	public override uint32 Height => 2;
	public override Span<uint8> PixelData => .(&mPixels[0], mPixels.Count);
	public override AtlasMode Mode => .DistanceField;
	public override float DistanceFieldRange => 4.0f;
	public override Float2 WhitePixelUV => .(0.5f, 0.5f);

	public override bool TryGetRegion(int32 codepoint, out AtlasRegion region)
	{
		region = default;
		return false;
	}

	public override bool GetGlyphQuad(int32 codepoint, ref float cursorX, float cursorY,
		out GlyphQuad quad)
	{
		quad = default;
		return false;
	}

	public override bool GetGlyphQuadAt(int32 codepoint, float x, float y, out GlyphQuad quad)
	{
		quad = default;
		return false;
	}

	public override bool Contains(int32 codepoint) => false;
}

class FakeDistanceFieldBaker : IFontAtlasBaker
{
	private static StringView[1] sExtensions = .(".ttf");

	public override Span<StringView> SupportedExtensions => sExtensions;
	public override bool SupportsExtension(StringView fileExtension) => fileExtension == ".ttf";

	public override bool CanBake(IFont font)
		=> (font != null) && (font.BackendTypeId == TrueTypeCommon.BackendTypeId);

	/// Distance field requests ONLY, which is what tells this apart from the raster baker
	/// over the same font.
	public override bool CanBake(IFont font, FontLoadOptions options)
		=> CanBake(font) && (options.AtlasMode == .DistanceField);

	public override Result<IFontAtlas, FontLoadResult> Bake(IFont font, FontLoadOptions options)
	{
		if (!CanBake(font))
			return .Err(.UnsupportedFormat);
		return .Ok(new FakeDistanceFieldAtlas());
	}
}
