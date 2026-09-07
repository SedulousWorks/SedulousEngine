using System;
using System.Collections;

namespace Sedulous.Fonts;

/// A base font seen at a different size.
///
/// Everything in screen space (metrics, advances, kerning, glyph boxes) multiplies by the
/// requested size over the baked size; the atlas is untouched. This is what makes ONE
/// distance field bake serve every size in a UI: the field resamples cleanly, so a service
/// answers a request for 12px out of a 48px bake by handing back a view rather than the
/// raw 48px tables, which would draw 48px shaped glyphs at 12px positions.
///
/// BORROWS the base, which the service owns and guarantees outlives the view.
class ScaledFontView : IFont
{
	private IFont mBase;
	private float mPixelHeight;
	private float mScale;

	public this(IFont baseFont, float pixelHeight)
	{
		mBase = baseFont;
		mPixelHeight = pixelHeight;
		// A base with no size of its own cannot be scaled against, so it passes through.
		mScale = (baseFont.PixelHeight > 0.0f) ? (pixelHeight / baseFont.PixelHeight) : 1.0f;
	}

	public float Scale => mScale;

	public override uint32 BackendTypeId => mBase.BackendTypeId;
	public override void GetFamilyName(String outName) => mBase.GetFamilyName(outName);
	public override float PixelHeight => mPixelHeight;

	public override FontMetrics Metrics
	{
		get
		{
			let b = mBase.Metrics;
			return .(b.Ascent * mScale, b.Descent * mScale, b.LineGap * mScale, mPixelHeight,
				b.Scale * mScale);
		}
	}

	public override GlyphInfo GetGlyphInfo(int32 codepoint)
	{
		var info = mBase.GetGlyphInfo(codepoint);
		info.AdvanceWidth *= mScale;
		info.LeftSideBearing *= mScale;
		info.BoundingBox.X *= mScale;
		info.BoundingBox.Y *= mScale;
		info.BoundingBox.Width *= mScale;
		info.BoundingBox.Height *= mScale;
		return info;
	}

	public override float GetKerning(int32 firstCodepoint, int32 secondCodepoint)
		=> mBase.GetKerning(firstCodepoint, secondCodepoint) * mScale;

	public override bool HasGlyph(int32 codepoint) => mBase.HasGlyph(codepoint);

	public override float MeasureString(StringView text) => mBase.MeasureString(text) * mScale;

	/// Laid out in the VIEW's space rather than scaled afterwards, so the advances and the
	/// kerning that place each glyph are the scaled ones throughout.
	public override float MeasureString(StringView text, List<GlyphPosition> outPositions)
	{
		outPositions.Clear();
		float x = 0.0f;
		int32 previousCodepoint = 0;
		int32 index = 0;
		int i = 0;
		while (i < text.Length)
		{
			let codepoint = (int32)DecodeCodepoint(text, ref i);
			let info = GetGlyphInfo(codepoint);
			if (previousCodepoint != 0)
				x += GetKerning(previousCodepoint, codepoint);

			var position = GlyphPosition();
			position.StringIndex = index;
			position.Codepoint = codepoint;
			position.X = x;
			position.Y = 0;
			position.Advance = info.AdvanceWidth;
			position.GlyphInfo = info;
			outPositions.Add(position);

			x += info.AdvanceWidth;
			previousCodepoint = codepoint;
			index++;
		}
		return x;
	}
}
