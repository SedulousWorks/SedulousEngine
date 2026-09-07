using System;
using System.Collections;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Coverage;

/// A font whose glyph and kerning tables were baked ahead of time.
///
/// No rasteriser behind it: everything it answers was worked out by whatever produced the
/// tables. That is what lets a shipped game carry fonts without linking a font parser, and
/// what lets a `.font` resource load straight into something drawable.
class BakedFont : IFont
{
	private String mFamilyName = new .() ~ delete _;
	private float mPixelHeight;
	private FontMetrics mMetrics = .Default();
	private Dictionary<int32, GlyphInfo> mGlyphs = new .() ~ delete _;
	/// Keyed on the PAIR, packed into one integer: kerning is a property of two codepoints
	/// together, and a packed key keeps the table a plain dictionary.
	private Dictionary<int64, float> mKerning = new .() ~ delete _;

	/// Empties every table in place, so the same instance can be refilled from disk.
	///
	/// In PLACE because a hot reload must not invalidate the references already handed
	/// out: a CachedFont, a shaper and every proxy hold this object, and replacing it would
	/// mean finding them all.
	public void ClearForReload()
	{
		mGlyphs.Clear();
		mKerning.Clear();
		mFamilyName.Clear();
		mPixelHeight = 0;
		mMetrics = .Default();
	}

	public void SetFamilyName(StringView name) => mFamilyName.Set(name);
	public void SetMetrics(FontMetrics metrics) => mMetrics = metrics;
	public void SetPixelHeight(float pixelHeight) => mPixelHeight = pixelHeight;
	public void SetGlyph(int32 codepoint, GlyphInfo info) => mGlyphs[codepoint] = info;

	public void SetKerning(int32 first, int32 second, float adjustment)
		=> mKerning[PackPair(first, second)] = adjustment;

	// ---- IFont ----

	public override void GetFamilyName(String outName) => outName.Append(mFamilyName);
	public override FontMetrics Metrics => mMetrics;
	public override float PixelHeight => mPixelHeight;

	/// A codepoint the bake did not cover answers a DEFAULT glyph rather than failing: it
	/// has no advance and nothing to draw, which is what an unbaked character should
	/// contribute to a line of text.
	public override GlyphInfo GetGlyphInfo(int32 codepoint)
	{
		if (mGlyphs.TryGetValue(codepoint, let info))
			return info;
		return .();
	}

	public override float GetKerning(int32 firstCodepoint, int32 secondCodepoint)
	{
		if (mKerning.TryGetValue(PackPair(firstCodepoint, secondCodepoint), let adjustment))
			return adjustment;
		return 0;
	}

	public override bool HasGlyph(int32 codepoint) => mGlyphs.ContainsKey(codepoint);

	public override float MeasureString(StringView text)
	{
		float width = 0;
		int32 previous = 0;
		int i = 0;
		while (i < text.Length)
		{
			let codepoint = (int32)DecodeCodepoint(text, ref i);
			// Kerning is between a pair, so it applies from the second glyph onward.
			if (previous != 0)
				width += GetKerning(previous, codepoint);
			width += GetGlyphInfo(codepoint).AdvanceWidth;
			previous = codepoint;
		}
		return width;
	}

	public override float MeasureString(StringView text, List<GlyphPosition> outPositions)
	{
		outPositions.Clear();

		float x = 0;
		int32 previous = 0;
		int32 index = 0;
		int i = 0;
		while (i < text.Length)
		{
			let codepoint = (int32)DecodeCodepoint(text, ref i);
			let info = GetGlyphInfo(codepoint);
			if (previous != 0)
				x += GetKerning(previous, codepoint);

			var position = GlyphPosition();
			position.StringIndex = index;
			position.Codepoint = codepoint;
			position.X = x;
			position.Y = 0;
			position.Advance = info.AdvanceWidth;
			position.GlyphInfo = info;
			outPositions.Add(position);

			x += info.AdvanceWidth;
			previous = codepoint;
			index++;
		}
		return x;
	}

	/// The tables themselves, for tooling that writes them out or reports on them.
	public Dictionary<int32, GlyphInfo> Glyphs => mGlyphs;
	public Dictionary<int64, float> Kerning => mKerning;

	/// The first codepoint in the high half, the second in the low.
	///
	/// The second is masked through UNSIGNED before widening: a negative codepoint would
	/// otherwise sign extend across the whole key and collide with an unrelated pair.
	private static int64 PackPair(int32 first, int32 second)
		=> ((int64)first << 32) | (int64)(uint32)second;
}
