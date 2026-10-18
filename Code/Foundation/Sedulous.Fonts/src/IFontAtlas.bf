using System;
using Sedulous.Core;

namespace Sedulous.Fonts;

/// A texture of pre-rendered glyphs, and where each one sits in it.
abstract class IFontAtlas
{
	public abstract uint32 Width { get; }
	public abstract uint32 Height { get; }
	/// Single channel eight bit coverage.
	public abstract Span<uint8> PixelData { get; }

	// Glyphs are looked up by glyph id, what a shaper writes into GlyphPosition.GlyphId. Text
	// drawn without a shaper maps each codepoint to its glyph with GlyphFor first.

	/// The glyph this atlas draws `codepoint` with, or -1 when it has none.
	public abstract int32 GlyphFor(int32 codepoint);

	public abstract bool TryGetRegion(int32 glyphId, out AtlasRegion region);

	/// Builds the quad for a glyph AND steps the cursor past it, which is the whole of
	/// drawing a run of text.
	///
	/// False means nothing to draw, not failure: whitespace has an advance and no pixels,
	/// and the cursor still moves.
	public abstract bool GetGlyphQuad(int32 glyphId, ref float cursorX, float cursorY, out GlyphQuad quad);

	/// The same quad at an absolute position, with no cursor to step.
	public abstract bool GetGlyphQuadAt(int32 glyphId, float x, float y, out GlyphQuad quad);

	public abstract bool Contains(int32 glyphId);

	/// A texel that is solid white, so a renderer can draw untextured geometry (a caret, an
	/// underline, a selection fill) from the SAME texture and the same draw call as the
	/// text. Without one, every rule under a line of text is a state change.
	public abstract Float2 WhitePixelUV { get; }

	/// Plain coverage unless a backend says otherwise, so an atlas written before distance
	/// fields existed keeps working.
	public virtual AtlasMode Mode => .Coverage;

	/// How far, in texels, the distance field spreads. Zero for a coverage atlas.
	public virtual float DistanceFieldRange => 0.0f;
}
