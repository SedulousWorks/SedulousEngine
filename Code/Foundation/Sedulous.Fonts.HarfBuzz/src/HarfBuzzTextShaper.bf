using System;
using System.Collections;
using harfbuzz_Beef;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;

namespace Sedulous.Fonts.HarfBuzz;

/// The HarfBuzz shaper.
///
/// Shapes UTF-32 codepoints, so HarfBuzz's clusters come back in characters, the unit
/// GlyphPosition clusters count, at the monotone-characters cluster level: a ligature is one
/// cluster over its characters, and a base and its marks share one. Positions arrive in font
/// units and scale to pixels by the font's Metrics.Scale; y offsets flip to y-down. Wrapping
/// shapes each paragraph whole and breaks it after spaces, so a ligature or a joined form never
/// splits across a break it would not have split at.
class HarfBuzzTextShaper : ClusterTextShaper
{
	/// For a font without its file, which HarfBuzz has nothing to read in.
	private TrueTypeTextShaper mFallback = new .() ~ delete _;
	private hb_font_t* mFont = null;
	/// Which file mFont reads, compared and never dereferenced: a shaper serves one font.
	private uint8* mData = null;
	private int mSize = 0;

	public ~this()
	{
		Release();
	}

	public override Result<float, FontLoadResult> ShapeText(IFont font, StringView text,
		List<GlyphPosition> outPositions)
		=> ShapeText(font, text, 0, 0, outPositions);

	public override Result<float, FontLoadResult> ShapeText(IFont font, StringView text,
		float startX, float startY, List<GlyphPosition> outPositions)
	{
		if (font == null)
			return mFallback.ShapeText(font, text, startX, startY, outPositions);
		let hbFont = FontFor(font);
		if (hbFont == null)
			return mFallback.ShapeText(font, text, startX, startY, outPositions);

		outPositions.Clear();
		let codepoints = scope List<uint32>();
		Decode(text, codepoints);
		return .Ok(ShapeCodepoints(font, hbFont, codepoints, 0, startX, startY, outPositions));
	}

	public override Result<void, FontLoadResult> ShapeTextWrapped(IFont font, StringView text,
		float maxWidth, List<GlyphPosition> outPositions, out float outTotalHeight)
	{
		if (font == null)
			return mFallback.ShapeTextWrapped(font, text, maxWidth, outPositions, out outTotalHeight);
		let hbFont = FontFor(font);
		if (hbFont == null)
			return mFallback.ShapeTextWrapped(font, text, maxWidth, outPositions, out outTotalHeight);

		outPositions.Clear();
		let lineHeight = font.Metrics.LineHeight;
		let codepoints = scope List<uint32>();
		Decode(text, codepoints);

		float y = 0;
		int start = 0;
		let run = scope List<uint32>();
		let paragraph = scope List<GlyphPosition>();
		while (start <= codepoints.Count)
		{
			// One paragraph: up to the next line break, which draws nothing.
			var end = start;
			while ((end < codepoints.Count) && (codepoints[end] != (uint32)'\n'))
				end++;
			run.Clear();
			for (int i = start; i < end; i++)
				run.Add((codepoints[i] != (uint32)'\r') ? codepoints[i] : (uint32)' '); // a CR keeps its character, as a space

			paragraph.Clear();
			ShapeCodepoints(font, hbFont, run, (int32)start, 0, 0, paragraph);
			y = WrapParagraph(paragraph, codepoints, maxWidth, lineHeight, y, outPositions);
			if (end >= codepoints.Count)
				break;
			y += lineHeight; // the break starts the next paragraph on a line of its own
			start = end + 1;
		}
		outTotalHeight = y + lineHeight;
		return .Ok;
	}

	/// The features shaping turns on by default whose substitutions bring in glyphs:
	/// ligatures, contextual and positional forms, the Indic and Arabic ones.
	private const String[?] cClosureFeatures = .("ccmp", "locl", "rlig", "liga", "clig", "calt", "rclt",
		"isol", "init", "medi", "med2", "fina", "fin2", "fin3", "nukt", "akhn", "rphf", "rkrf", "pref",
		"blwf", "abvf", "half", "pstf", "vatu", "cjct", "pres", "abvs", "blws", "psts", "haln", "ljmo",
		"vjmo", "tjmo");

	/// The GSUB closure of the codepoints' glyphs under those features, less the glyphs the
	/// codepoints map to themselves.
	public override void CollectReachableGlyphs(IFont font, Span<int32> codepoints, List<int32> outGlyphs)
	{
		outGlyphs.Clear();
		let hbFont = FontFor(font);
		if (hbFont == null)
			return;
		let face = hb_font_get_face(hbFont);

		let nominal = hb_set_create();
		defer hb_set_destroy(nominal);
		for (let codepoint in codepoints)
		{
			hb_codepoint_t glyph = 0;
			if ((codepoint > 0) && (hb_font_get_nominal_glyph(hbFont, (uint32)codepoint, &glyph) != 0))
				hb_set_add(nominal, glyph);
		}

		hb_tag_t[cClosureFeatures.Count + 1] features = default; // ends in HB_TAG_NONE
		for (int i < cClosureFeatures.Count)
		{
			let name = cClosureFeatures[i];
			features[i] = HB_TAG(name[0], name[1], name[2], name[3]);
		}
		let lookups = hb_set_create();
		defer hb_set_destroy(lookups);
		hb_ot_layout_collect_lookups(face, HB_OT_TAG_GSUB, null, null, &features[0], lookups);

		let glyphs = hb_set_create();
		defer hb_set_destroy(glyphs);
		hb_set_union(glyphs, nominal);
		hb_ot_layout_lookups_substitute_closure(face, lookups, glyphs);
		hb_set_subtract(glyphs, nominal);
		var glyph = HB_SET_VALUE_INVALID;
		while (hb_set_next(glyphs, &glyph) != 0)
			outGlyphs.Add((int32)glyph);
	}

	/// Shapes `codepoints` (the characters from `clusterBase` on) and appends their glyphs at
	/// (startX, startY). Returns the advance.
	private float ShapeCodepoints(IFont font, hb_font_t* hbFont, List<uint32> codepoints,
		int32 clusterBase, float startX, float startY, List<GlyphPosition> outPositions)
	{
		if (codepoints.IsEmpty)
			return 0;

		let buffer = hb_buffer_create();
		defer hb_buffer_destroy(buffer);
		hb_buffer_set_cluster_level(buffer, .HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS);
		hb_buffer_add_utf32(buffer, codepoints.Ptr, (int32)codepoints.Count, 0, (int32)codepoints.Count);
		hb_buffer_guess_segment_properties(buffer);
		hb_shape(hbFont, buffer, null, 0);

		uint32 count = 0;
		let infos = hb_buffer_get_glyph_infos(buffer, &count);
		let positions = hb_buffer_get_glyph_positions(buffer, &count);

		// A cluster runs to the next cluster that starts after it, in characters.
		let starts = scope List<uint32>();
		for (uint32 i < count)
			starts.Add(infos[i].cluster);
		starts.Sort();

		let scale = font.Metrics.Scale;
		var x = startX;
		for (uint32 i < count)
		{
			let cluster = infos[i].cluster;
			var clusterEnd = (uint32)codepoints.Count;
			for (let s in starts)
			{
				if (s > cluster)
				{
					clusterEnd = s;
					break;
				}
			}

			var glyph = GlyphPosition();
			glyph.Cluster = clusterBase + (int32)cluster;
			glyph.ClusterLength = (int32)(clusterEnd - cluster);
			glyph.GlyphId = (int32)infos[i].codepoint;
			glyph.X = x;
			glyph.Y = startY;
			glyph.Advance = (float)positions[i].x_advance * scale;
			glyph.XOffset = (float)positions[i].x_offset * scale;
			glyph.YOffset = -(float)positions[i].y_offset * scale; // y-up to y-down
			glyph.GlyphInfo.Codepoint = (int32)codepoints[cluster];
			glyph.GlyphInfo.GlyphIndex = glyph.GlyphId;
			glyph.GlyphInfo.AdvanceWidth = glyph.Advance;
			outPositions.Add(glyph);
			x += glyph.Advance;
		}
		return x - startX;
	}

	/// Lays one shaped paragraph into lines no wider than `maxWidth`, breaking after the last
	/// space that fits, or before an overflowing glyph when a word alone is too wide. Returns
	/// the y of its last line.
	private static float WrapParagraph(List<GlyphPosition> glyphs, List<uint32> text, float maxWidth,
		float lineHeight, float y, List<GlyphPosition> outPositions)
	{
		var y;
		int lineStart = 0;
		while (lineStart < glyphs.Count)
		{
			let origin = glyphs[lineStart].X;
			var lastBreak = glyphs.Count; // the glyph after which the line may end
			var end = lineStart;
			for (; end < glyphs.Count; end++)
			{
				let glyph = glyphs[end];
				let space = (glyph.Cluster >= 0) && (glyph.Cluster < text.Count) && (text[glyph.Cluster] == (uint32)' ');
				if (((glyph.X + glyph.Advance - origin) > maxWidth) && (end > lineStart) && !space)
					break;
				if (space)
					lastBreak = end;
			}

			var next = end;
			if ((end < glyphs.Count) && (lastBreak < glyphs.Count) && (lastBreak >= lineStart))
				next = lastBreak + 1; // wrap after the space
			for (int i = lineStart; i < next; i++)
			{
				var glyph = glyphs[i];
				glyph.X -= origin;
				glyph.Y = y;
				outPositions.Add(glyph);
			}
			lineStart = next;
			if (lineStart < glyphs.Count)
				y += lineHeight;
		}
		return y;
	}

	private static void Decode(StringView text, List<uint32> outCodepoints)
	{
		outCodepoints.Clear();
		int index = 0;
		while (index < text.Length)
			outCodepoints.Add(DecodeCodepoint(text, ref index));
	}

	/// The HarfBuzz font for `font`, made once per font file; null when the font has no file
	/// to read.
	private hb_font_t* FontFor(IFont font)
	{
		let data = font.SourceData;
		if (data.IsEmpty)
			return null;
		if ((mFont != null) && (mData == data.Ptr) && (mSize == data.Length))
			return mFont;

		Release();
		let blob = hb_blob_create((char8*)data.Ptr, (uint32)data.Length, .HB_MEMORY_MODE_READONLY, null, null);
		let face = hb_face_create(blob, 0);
		hb_blob_destroy(blob); // the face holds it
		mFont = hb_font_create(face); // scale is units per em: positions come in font units
		hb_face_destroy(face); // the font holds it
		mData = data.Ptr;
		mSize = data.Length;
		return mFont;
	}

	private void Release()
	{
		if (mFont != null)
			hb_font_destroy(mFont);
		mFont = null;
		mData = null;
		mSize = 0;
	}
}
