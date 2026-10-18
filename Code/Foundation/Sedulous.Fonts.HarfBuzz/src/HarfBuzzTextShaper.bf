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
	/// A HarfBuzz font for one font file this shaper has shaped with.
	struct CachedFont
	{
		public hb_font_t* Font;
		/// Which file it reads, compared and never dereferenced.
		public uint8* Data;
		public int Size;
	}

	/// For a font without its file, which HarfBuzz has nothing to read in.
	private TrueTypeTextShaper mFallback = new .() ~ delete _;
	/// Its own font, and any a request falls back to.
	private List<CachedFont> mFonts = new .() ~ delete _;

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
		IFont[1] fonts = .(font);
		var request = ShapeRequest(text, fonts);
		request.StartX = startX;
		request.StartY = startY;
		return Shape(request, outPositions);
	}

	/// Runs by font, then by script within each (a character of no particular script, a space
	/// or a digit, joins the run around it), each shaped with its direction, script and language;
	/// runs are laid one after the other: reordering runs is bidi's.
	public override Result<float, FontLoadResult> Shape(ShapeRequest request, List<GlyphPosition> outPositions)
	{
		outPositions.Clear();
		let codepoints = scope List<uint32>();
		let bytes = scope List<int>();
		DecodeWithOffsets(request.Text, codepoints, bytes);
		let runs = scope List<FontRun>();
		ItemizeByFont(request.Fonts, codepoints, bytes, runs);
		let language = request.Language.IsEmpty ? HB_LANGUAGE_INVALID
			: hb_language_from_string(request.Language.Ptr, (int32)request.Language.Length);
		let direction = (request.Direction == .LeftToRight) ? hb_direction_t.HB_DIRECTION_LTR
			: ((request.Direction == .RightToLeft) ? hb_direction_t.HB_DIRECTION_RTL : hb_direction_t.HB_DIRECTION_INVALID);

		var x = request.StartX;
		let fallback = scope List<GlyphPosition>();
		let run = scope List<uint32>();
		for (let fontRun in runs)
		{
			let font = request.Fonts[fontRun.Font];
			if (font == null)
				continue;
			let first = outPositions.Count;
			let hbFont = FontFor(font);
			if (hbFont == null)
			{
				// No file to read: the basic shaper, run by run.
				let text = request.Text.Substring(fontRun.ByteStart, fontRun.ByteEnd - fontRun.ByteStart);
				if (mFallback.ShapeText(font, text, x, request.StartY, fallback) case .Ok(let advance))
				{
					for (var glyph in fallback)
					{
						glyph.Cluster += (int32)fontRun.Start;
						outPositions.Add(glyph);
					}
					x += advance;
				}
			}
			else
			{
				var start = fontRun.Start;
				while (start < fontRun.End)
				{
					var script = HB_SCRIPT_INVALID;
					var end = fontRun.End;
					if (request.Script != 0)
						script = hb_script_from_iso15924_tag(request.Script);
					else
						end = ScriptRunEnd(codepoints, start, fontRun.End, out script);
					run.Clear();
					for (int i = start; i < end; i++)
						run.Add(codepoints[i]);
					x += ShapeCodepoints(font, hbFont, run, (int32)start, x, request.StartY, outPositions,
						script, direction, language);
					start = end;
				}
			}
			for (int i = first; i < outPositions.Count; i++)
				outPositions[i].Font = fontRun.Font;
		}
		return .Ok(x - request.StartX);
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
			ShapeCodepoints(font, hbFont, run, (int32)start, 0, 0, paragraph,
				HB_SCRIPT_INVALID, .HB_DIRECTION_INVALID, HB_LANGUAGE_INVALID);
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
	/// (startX, startY). Returns the advance. A script, direction or language left invalid is
	/// guessed from the characters.
	private float ShapeCodepoints(IFont font, hb_font_t* hbFont, List<uint32> codepoints,
		int32 clusterBase, float startX, float startY, List<GlyphPosition> outPositions,
		hb_script_t script, hb_direction_t direction, hb_language_t language)
	{
		if (codepoints.IsEmpty)
			return 0;

		let buffer = hb_buffer_create();
		defer hb_buffer_destroy(buffer);
		hb_buffer_set_cluster_level(buffer, .HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS);
		hb_buffer_add_utf32(buffer, codepoints.Ptr, (int32)codepoints.Count, 0, (int32)codepoints.Count);
		if (script != HB_SCRIPT_INVALID)
			hb_buffer_set_script(buffer, script);
		var direction;
		if ((direction == .HB_DIRECTION_INVALID) && (script != HB_SCRIPT_INVALID))
			direction = hb_script_get_horizontal_direction(script);
		if (direction != .HB_DIRECTION_INVALID)
			hb_buffer_set_direction(buffer, direction);
		if (language != HB_LANGUAGE_INVALID)
			hb_buffer_set_language(buffer, language);
		hb_buffer_guess_segment_properties(buffer); // fills only what is still unset
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

	/// The end of the script run starting at `start` (within [start, end)), and its script. A
	/// character of no particular script (common, inherited) belongs to the run it is in.
	private static int ScriptRunEnd(List<uint32> codepoints, int start, int end, out hb_script_t outScript)
	{
		let unicode = hb_unicode_funcs_get_default();
		outScript = HB_SCRIPT_INVALID;
		for (int i = start; i < end; i++)
		{
			let script = hb_unicode_script(unicode, codepoints[i]);
			if ((script == HB_SCRIPT_COMMON) || (script == HB_SCRIPT_INHERITED) || (script == HB_SCRIPT_UNKNOWN))
				continue;
			if (outScript == HB_SCRIPT_INVALID)
				outScript = script;
			else if (script != outScript)
				return i; // the new script starts a run; spaces before it stay behind
		}
		return end;
	}

	/// The HarfBuzz font for `font`, made once per font file; null when the font has no file
	/// to read.
	private hb_font_t* FontFor(IFont font)
	{
		let data = font.SourceData;
		if (data.IsEmpty)
			return null;
		for (let cached in mFonts)
		{
			if ((cached.Data == data.Ptr) && (cached.Size == data.Length))
				return cached.Font;
		}

		let blob = hb_blob_create((char8*)data.Ptr, (uint32)data.Length, .HB_MEMORY_MODE_READONLY, null, null);
		let face = hb_face_create(blob, 0);
		hb_blob_destroy(blob); // the face holds it
		var cached = CachedFont();
		cached.Font = hb_font_create(face); // scale is units per em: positions come in font units
		hb_face_destroy(face); // the font holds it
		cached.Data = data.Ptr;
		cached.Size = data.Length;
		mFonts.Add(cached);
		return cached.Font;
	}

	private void Release()
	{
		for (let cached in mFonts)
			hb_font_destroy(cached.Font);
		mFonts.Clear();
	}
}
