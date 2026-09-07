using System;
using System.Collections;

namespace Sedulous.Fonts;

/// A font that has been loaded and can answer questions about its glyphs.
///
/// An abstract class rather than an interface because CachedFont owns and deletes what it
/// is handed, and that needs a destructor to dispatch through.
abstract class IFont
{
	/// A backend's own type tag, for recovering a concrete font without RTTI.
	///
	/// A baker is usually paired with one parser and needs its parser's concrete font type
	/// back. Comparing a tag is what stands in for a dynamic cast; zero means the backend
	/// did not claim one, so a baker matching on zero would match everything and must not.
	public virtual uint32 BackendTypeId => 0;

	public abstract void GetFamilyName(String outName);
	public abstract FontMetrics Metrics { get; }
	public abstract float PixelHeight { get; }

	/// The glyph for a codepoint the font does not have is the MISSING glyph, not a
	/// failure: text renders with a visible box rather than silently losing characters.
	public abstract GlyphInfo GetGlyphInfo(int32 codepoint);
	public abstract float GetKerning(int32 firstCodepoint, int32 secondCodepoint);
	public abstract bool HasGlyph(int32 codepoint);

	public abstract float MeasureString(StringView text);
	/// Measures AND lays out, so a caller that needs both does not walk the string twice.
	public abstract float MeasureString(StringView text, List<GlyphPosition> outPositions);
}
