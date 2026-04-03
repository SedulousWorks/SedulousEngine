using System;
using System.Collections;

namespace Sedulous.Slug;

/// All data needed to render a single glyph with Slug.
/// This is the format-agnostic representation - populated by
/// Sedulous.Slug.TTF or any other curve source.
public class SlugGlyphData
{
	/// Unicode codepoint this glyph represents.
	public uint32 Codepoint;
	/// Glyph index within the font.
	public int32 GlyphIndex;
	/// Horizontal advance width in em units.
	public float AdvanceWidth;
	/// Left side bearing in em units.
	public float LeftSideBearing;
	/// Bounding box in em-space.
	public Box2D BoundingBox;
	/// The quadratic Bézier curves defining this glyph's contours.
	public QuadraticBezier2D[] Curves ~ delete _;

	// -- Populated by SlugTextureBuilder --

	/// Location of this glyph's data in the band texture [x, y].
	public uint16[2] BandLocation;
	/// Number of horizontal and vertical bands.
	public int16[2] BandCount;
	/// Scale for computing band indices from em-space coordinates.
	public Vector2D BandScale;

	/// Whether this glyph has visible curves.
	public bool HasCurves => Curves != null && Curves.Count > 0;
}

/// Font-level metrics in em units (unscaled).
public struct SlugFontMetrics
{
	/// Ascent above baseline in em units.
	public float Ascent;
	/// Descent below baseline in em units (typically negative).
	public float Descent;
	/// Line gap in em units.
	public float LineGap;
	/// Units per em (typically 1.0 after normalization, or raw from font).
	public float UnitsPerEm;
	/// Cap height in em units (height of 'H'). Used for pixel-grid alignment.
	public float CapHeight;

	/// Default line height: Ascent - Descent + LineGap
	public float LineHeight => Ascent - Descent + LineGap;

	/// Snap a font size so that cap height aligns to the pixel grid.
	/// This eliminates subtle vertical blurriness at common text sizes.
	/// Pass monitor DPI scale if not 1.0 (e.g., 1.25, 1.5, 2.0).
	public float AlignFontSize(float requestedSize, float dpiScale = 1.0f)
	{
		if (CapHeight <= 0)
			return requestedSize;

		let capHeightPixels = requestedSize * CapHeight * dpiScale;
		let rounded = Math.Round(capHeightPixels);
		if (rounded <= 0)
			return requestedSize;

		return (float)rounded / (CapHeight * dpiScale);
	}
}

/// A complete Slug font: metrics + glyph data, ready for texture building and rendering.
/// This is the main font object - format-agnostic, populated by a loader (e.g. Sedulous.Slug.TTF).
public class SlugFont : IDisposable
{
	private Dictionary<uint32, SlugGlyphData> mGlyphs = new .() ~ {
		for (let kv in _) delete kv.value;
		delete _;
	};

	/// Font metrics.
	public SlugFontMetrics Metrics;

	/// Font family name.
	public String FamilyName = new .() ~ delete _;

	/// Number of glyphs loaded.
	public int32 GlyphCount => (int32)mGlyphs.Count;

	/// Whether textures have been built for this font.
	public bool TexturesBuilt { get; set; }

	/// Add a glyph to the font. Takes ownership.
	public void AddGlyph(SlugGlyphData glyph)
	{
		mGlyphs[glyph.Codepoint] = glyph;
	}

	/// Get glyph data for a codepoint. Returns null if not found.
	public SlugGlyphData GetGlyph(uint32 codepoint)
	{
		if (mGlyphs.TryGetValue(codepoint, let glyph))
			return glyph;
		return null;
	}

	/// Get glyph data for a codepoint, or the missing glyph (codepoint 0).
	public SlugGlyphData GetGlyphOrDefault(uint32 codepoint)
	{
		if (mGlyphs.TryGetValue(codepoint, let glyph))
			return glyph;
		if (mGlyphs.TryGetValue(0, let fallback))
			return fallback;
		return null;
	}

	/// Check if font has a glyph for this codepoint.
	public bool HasGlyph(uint32 codepoint)
	{
		return mGlyphs.ContainsKey(codepoint);
	}

	/// Iterate all glyphs.
	public Dictionary<uint32, SlugGlyphData>.ValueEnumerator Glyphs => mGlyphs.Values;

	/// Get the advance width for a codepoint in em units.
	public float GetAdvanceWidth(uint32 codepoint)
	{
		let glyph = GetGlyph(codepoint);
		return (glyph != null) ? glyph.AdvanceWidth : 0.0f;
	}

	public void Dispose()
	{
		// Destructor handles cleanup via ~ expressions
	}
}
