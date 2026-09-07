using System;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.Fonts.TrueType;

/// Bakes a parsed TrueType font into a coverage atlas.
class TrueTypeFontAtlasBaker : IFontAtlasBaker
{
	public override Span<StringView> SupportedExtensions => TrueTypeCommon.Extensions;

	public override bool SupportsExtension(StringView fileExtension)
		=> TrueTypeCommon.IsSupportedExtension(fileExtension);

	public override bool CanBake(IFont font)
		=> (font != null) && (font.BackendTypeId == TrueTypeCommon.BackendTypeId);

	/// COVERAGE only. A distance field request over the same font belongs to the MSDF
	/// baker, and the two are told apart by the mode alone: they take the same font type,
	/// so without this check whichever registered first would answer for both.
	public override bool CanBake(IFont font, FontLoadOptions options)
		=> CanBake(font) && (options.AtlasMode == .Coverage);

	public override Result<IFontAtlas, FontLoadResult> Bake(IFont font, FontLoadOptions options)
	{
		if (!CanBake(font))
			return .Err(.UnsupportedFormat);

		let atlas = new TrueTypeFontAtlas();
		let result = atlas.Create((TrueTypeFont)font, options);
		if (result != .Success)
		{
			delete atlas;
			return .Err(result);
		}
		return .Ok(atlas);
	}
}
