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
/// units and scale to pixels by the font's Metrics.Scale; y offsets flip to y-down. A line's runs
/// come from the installed bidi resolver and are laid out in visual order. Wrapping measures each
/// paragraph in logical runs and breaks after spaces, so a ligature or a joined form never splits
/// across a break it would not have split at, and right-to-left text reorders by line.
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

	/// Each paragraph (up to a line break, which draws nothing): its levels resolved, its
	/// characters measured in logical order, lines broken after the last space that fits (or
	/// before the character that overflows when a word alone is too wide), and each line laid out
	/// in visual order, so a ligature is never split and right-to-left text reorders by line.
	public override Result<void, FontLoadResult> ShapeTextWrapped(IFont font, StringView text,
		float maxWidth, List<GlyphPosition> outPositions, out float outTotalHeight)
	{
		if ((font == null) || (FontFor(font) == null))
			return mFallback.ShapeTextWrapped(font, text, maxWidth, outPositions, out outTotalHeight);

		outPositions.Clear();
		let lineHeight = font.Metrics.LineHeight;
		let codepoints = scope List<uint32>();
		let bytes = scope List<int>();
		DecodeWithOffsets(text, codepoints, bytes);
		IFont[1] fonts = .(font);
		let request = ShapeRequest(text, fonts);

		float y = 0;
		int start = 0;
		let measured = scope List<GlyphPosition>();
		let widths = scope List<float>();
		let levels = scope BidiLevels();
		while (start <= codepoints.Count)
		{
			var end = start;
			while ((end < codepoints.Count) && (codepoints[end] != (uint32)'\n'))
				end++;
			if (end > start)
			{
				let resolved = ResolveLevels(.Auto, codepoints, start, end, levels);
				// Each character's share of the advance, shaped in logical runs of one level.
				widths.Clear();
				widths.Resize(end - start);
				for (var width in ref widths)
					width = 0;
				var runStart = start;
				while (runStart < end)
				{
					var runEnd = end;
					var direction = RunDirection.Auto;
					if (resolved)
					{
						let level = levels.Levels[runStart - start];
						runEnd = runStart + 1;
						while ((runEnd < end) && (levels.Levels[runEnd - start] == level))
							runEnd++;
						direction = ((level & 1) != 0) ? .RightToLeft : .LeftToRight;
					}
					measured.Clear();
					ShapeRun(request, codepoints, bytes, runStart, runEnd, direction, 0, 0, measured);
					for (let glyph in measured)
					{
						if ((glyph.Cluster >= start) && (glyph.Cluster < end))
							widths[glyph.Cluster - start] += glyph.Advance;
					}
					runStart = runEnd;
				}

				var lineStart = start;
				while (lineStart < end)
				{
					float width = 0;
					var lastSpace = end; // none yet
					var lineEnd = lineStart;
					for (; lineEnd < end; lineEnd++)
					{
						let space = codepoints[lineEnd] == (uint32)' ';
						if (((width + widths[lineEnd - start]) > maxWidth) && (lineEnd > lineStart) && !space)
							break;
						if (space)
							lastSpace = lineEnd;
						width += widths[lineEnd - start];
					}
					var next = lineEnd;
					if ((lineEnd < end) && (lastSpace < end) && (lastSpace >= lineStart))
						next = lastSpace + 1;
					ShapeLine(request, codepoints, bytes, lineStart, next, resolved ? levels : null, 0, y,
						outPositions, start);
					lineStart = next;
					if (lineStart < end)
						y += lineHeight;
				}
			}
			if (end >= codepoints.Count)
				break;
			y += lineHeight; // the break starts the next paragraph on a line of its own
			start = end + 1;
		}
		outTotalHeight = y + lineHeight;
		return .Ok;
	}

	/// A piece of a run: characters in one font and one script.
	struct Piece
	{
		public int Start;
		public int End;
		public uint8 Font;
		public hb_script_t Script;
	}

	/// Characters [start, end) as runs by font, then by script; each shaped in the run's
	/// direction (or its script's), with the request's script and language. In a right-to-left
	/// run the pieces are laid right to left. A font without its file is shaped by the basic
	/// shaper.
	protected override Result<float, FontLoadResult> ShapeRun(ShapeRequest request, List<uint32> codepoints,
		List<int> byteOffsets, int start, int end, RunDirection direction, float x, float y,
		List<GlyphPosition> outPositions)
	{
		let language = request.Language.IsEmpty ? HB_LANGUAGE_INVALID
			: hb_language_from_string(request.Language.Ptr, (int32)request.Language.Length);

		// The pieces, in logical order.
		let sub = scope List<uint32>();
		let subBytes = scope List<int>();
		for (int i = start; i < end; i++)
		{
			sub.Add(codepoints[i]);
			subBytes.Add(byteOffsets[i]);
		}
		subBytes.Add(byteOffsets[end]);
		let runs = scope List<FontRun>();
		ItemizeByFont(request.Fonts, sub, subBytes, runs);
		let pieces = scope List<Piece>();
		for (let fontRun in runs)
		{
			var at = start + fontRun.Start;
			let runEnd = start + fontRun.End;
			while (at < runEnd)
			{
				var piece = Piece();
				piece.Start = at;
				piece.Font = fontRun.Font;
				if (request.Script != 0)
				{
					piece.End = runEnd;
					piece.Script = hb_script_from_iso15924_tag(request.Script);
				}
				else
				{
					piece.End = ScriptRunEnd(codepoints, at, runEnd, out piece.Script);
				}
				pieces.Add(piece);
				at = piece.End;
			}
		}

		let reversed = direction == .RightToLeft;
		hb_direction_t hbDirection;
		switch (direction)
		{
		case .LeftToRight: hbDirection = .HB_DIRECTION_LTR;
		case .RightToLeft: hbDirection = .HB_DIRECTION_RTL;
		case .Auto: hbDirection = .HB_DIRECTION_INVALID;
		}
		var x;
		let startX = x;
		let fallback = scope List<GlyphPosition>();
		let run = scope List<uint32>();
		for (int k < pieces.Count)
		{
			let piece = pieces[reversed ? (pieces.Count - 1 - k) : k];
			let font = request.Fonts[piece.Font];
			if (font == null)
				continue;
			let first = outPositions.Count;
			let hbFont = FontFor(font);
			if (hbFont == null)
			{
				let text = request.Text.Substring(byteOffsets[piece.Start], byteOffsets[piece.End] - byteOffsets[piece.Start]);
				if (mFallback.ShapeText(font, text, x, y, fallback) case .Ok(let advance))
				{
					for (var glyph in fallback)
					{
						glyph.Cluster += (int32)piece.Start;
						outPositions.Add(glyph);
					}
					x += advance;
				}
			}
			else
			{
				run.Clear();
				for (int i = piece.Start; i < piece.End; i++)
					run.Add(codepoints[i]);
				x += ShapeCodepoints(font, hbFont, run, (int32)piece.Start, x, y, outPositions,
					piece.Script, hbDirection, language);
			}
			for (int i = first; i < outPositions.Count; i++)
			{
				outPositions[i].Font = piece.Font;
				if (reversed)
					outPositions[i].RightToLeft = true;
			}
		}
		return .Ok(x - startX);
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
