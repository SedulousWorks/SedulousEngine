using System;
using System.Collections;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Baked;

/// IFont implementation backed by pre-baked glyph + kerning tables. No
/// stb_truetype dependency: shipped games get everything from disk via
/// FontResource deserialization.
public class BakedFont : IFont
{
	private String mFamilyName = new .() ~ delete _;
	private float mPixelHeight;
	private FontMetrics mMetrics;

	private Dictionary<int32, GlyphInfo> mGlyphs = new .() ~ delete _;

	/// Kerning pairs packed as (first << 32) | (second & 0xFFFFFFFF). Keeps
	/// the key compact + hashable without inventing a tuple key.
	private Dictionary<int64, float> mKerning = new .() ~ delete _;

	public String FamilyName => mFamilyName;
	public FontMetrics Metrics => mMetrics;
	public float PixelHeight => mPixelHeight;

	/// All baked glyphs - exposed for callers that want to iterate (e.g. the
	/// font editor page listing available characters).
	public Dictionary<int32, GlyphInfo> Glyphs => mGlyphs;
	public Dictionary<int64, float> Kerning => mKerning;

	public this() { }

	/// Clears all glyph + kerning tables and resets metadata back to
	/// empty in-place. Used by resource hot-reload so the same
	/// `BakedFont` instance can be re-populated from disk without
	/// invalidating outside references.
	public void ClearForReload()
	{
		mGlyphs.Clear();
		mKerning.Clear();
		mFamilyName.Clear();
		mPixelHeight = 0;
		mMetrics = .Default;
	}

	public void SetFamilyName(StringView name) { mFamilyName.Set(name); }
	public void SetMetrics(FontMetrics m) { mMetrics = m; }
	public void SetPixelHeight(float h) { mPixelHeight = h; }

	public void SetGlyph(int32 codepoint, GlyphInfo info)
	{
		mGlyphs[codepoint] = info;
	}

	public void SetKerning(int32 first, int32 second, float adjustment)
	{
		mKerning[PackKey(first, second)] = adjustment;
	}

	public GlyphInfo GetGlyphInfo(int32 codepoint)
	{
		if (mGlyphs.TryGetValue(codepoint, let info))
			return info;
		return .();
	}

	public float GetKerning(int32 firstCodepoint, int32 secondCodepoint)
	{
		if (mKerning.TryGetValue(PackKey(firstCodepoint, secondCodepoint), let adj))
			return adj;
		return 0;
	}

	public bool HasGlyph(int32 codepoint) => mGlyphs.ContainsKey(codepoint);

	public float MeasureString(StringView text)
	{
		float width = 0;
		int32 prevCodepoint = 0;
		for (let c in text.DecodedChars)
		{
			let codepoint = (int32)c;
			let info = GetGlyphInfo(codepoint);
			if (prevCodepoint != 0)
				width += GetKerning(prevCodepoint, codepoint);
			width += info.AdvanceWidth;
			prevCodepoint = codepoint;
		}
		return width;
	}

	public float MeasureString(StringView text, List<GlyphPosition> outPositions)
	{
		float x = 0;
		int32 prevCodepoint = 0;
		int32 index = 0;
		outPositions.Clear();
		for (let c in text.DecodedChars)
		{
			let codepoint = (int32)c;
			let info = GetGlyphInfo(codepoint);
			if (prevCodepoint != 0)
				x += GetKerning(prevCodepoint, codepoint);
			outPositions.Add(.(index, codepoint, x, 0, info.AdvanceWidth, info));
			x += info.AdvanceWidth;
			prevCodepoint = codepoint;
			index++;
		}
		return x;
	}

	[Inline]
	private static int64 PackKey(int32 first, int32 second)
	{
		return ((int64)first << 32) | ((int64)(uint32)second);
	}
}
