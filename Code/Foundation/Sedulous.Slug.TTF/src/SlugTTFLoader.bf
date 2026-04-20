using System;
using System.IO;
using System.Collections;
using System.Interop;
using stb_truetype;
using Sedulous.Slug;

namespace Sedulous.Slug.TTF;

/// Error codes for TTF loading.
public enum SlugTTFLoadResult
{
	Success,
	FileNotFound,
	ReadError,
	InvalidFont,
	NoGlyphs
}

/// Loads TTF/OTF fonts and extracts quadratic Bézier curves for Slug rendering.
public static class SlugTTFLoader
{
	/// Load a TTF/OTF file and create a SlugFont with all glyph curves extracted.
	/// The caller owns the returned SlugFont.
	public static Result<SlugFont, SlugTTFLoadResult> LoadFromFile(
		StringView filePath,
		int32 firstCodepoint = 32,
		int32 lastCodepoint = 126)
	{
		if (!File.Exists(filePath))
			return .Err(.FileNotFound);
		List<uint8> data = scope .();
		let readResult = File.ReadAll(filePath, data);
		if (readResult case .Err)
			return .Err(.ReadError);

		return LoadFromMemory(data, firstCodepoint, lastCodepoint);
	}

	/// Load a font from memory and create a SlugFont with all glyph curves extracted.
	public static Result<SlugFont, SlugTTFLoadResult> LoadFromMemory(
		Span<uint8> data,
		int32 firstCodepoint = 32,
		int32 lastCodepoint = 126)
	{
		stbtt_fontinfo fontInfo = .();
		if (stbtt_InitFont(&fontInfo, data.Ptr, 0) == 0)
			return .Err(.InvalidFont);

		let font = new SlugFont();

		// Get font metrics
		int32 ascent = 0, descent = 0, lineGap = 0;
		stbtt_GetFontVMetrics(&fontInfo, &ascent, &descent, &lineGap);
		let scale = stbtt_ScaleForMappingEmToPixels(&fontInfo, 1.0f); // Scale to get em units

		// Measure cap height from 'H' glyph bounding box
		float capHeight = 0;
		let hGlyph = stbtt_FindGlyphIndex(&fontInfo, (int32)'H');
		if (hGlyph != 0)
		{
			int32 hx0 = 0, hy0 = 0, hx1 = 0, hy1 = 0;
			stbtt_GetGlyphBox(&fontInfo, hGlyph, &hx0, &hy0, &hx1, &hy1);
			capHeight = (float)(hy1 - hy0) * scale;
		}

		font.Metrics = .() {
			Ascent = (float)ascent * scale,
			Descent = (float)descent * scale,
			LineGap = (float)lineGap * scale,
			UnitsPerEm = 1.0f / scale,
			CapHeight = capHeight
		};

		// Extract glyphs
		for (int32 cp = firstCodepoint; cp <= lastCodepoint; cp++)
		{
			let glyphIndex = stbtt_FindGlyphIndex(&fontInfo, cp);
			if (glyphIndex == 0 && cp != 0)
				continue;

			let glyphData = ExtractGlyph(&fontInfo, cp, glyphIndex, scale);
			if (glyphData != null)
				font.AddGlyph(glyphData);
		}

		// Also extract space (codepoint 32) explicitly if not already
		if (!font.HasGlyph(32))
		{
			let spaceIndex = stbtt_FindGlyphIndex(&fontInfo, 32);
			if (spaceIndex != 0)
			{
				let spaceData = ExtractGlyph(&fontInfo, 32, spaceIndex, scale);
				if (spaceData != null)
					font.AddGlyph(spaceData);
			}
		}

		if (font.GlyphCount == 0)
		{
			delete font;
			return .Err(.NoGlyphs);
		}

		return .Ok(font);
	}

	/// Extract a single glyph's curves and metrics.
	private static SlugGlyphData ExtractGlyph(stbtt_fontinfo* fontInfo, int32 codepoint, int32 glyphIndex, float scale)
	{
		// Get metrics
		int32 advanceWidth = 0, leftSideBearing = 0;
		stbtt_GetGlyphHMetrics(fontInfo, glyphIndex, &advanceWidth, &leftSideBearing);

		int32 x0 = 0, y0 = 0, x1 = 0, y1 = 0;
		stbtt_GetGlyphBox(fontInfo, glyphIndex, &x0, &y0, &x1, &y1);

		let glyph = new SlugGlyphData();
		glyph.Codepoint = (uint32)codepoint;
		glyph.GlyphIndex = glyphIndex;
		glyph.AdvanceWidth = (float)advanceWidth * scale;
		glyph.LeftSideBearing = (float)leftSideBearing * scale;

		// Extract contour curves (Y negated to convert from font Y-up to screen Y-down)
		if (stbtt_IsGlyphEmpty(fontInfo, glyphIndex) == 0)
		{
			stbtt_vertex* vertices = null;
			let vertexCount = stbtt_GetGlyphShape(fontInfo, glyphIndex, &vertices);

			if (vertexCount > 0 && vertices != null)
			{
				let curves = ExtractCurves(vertices, vertexCount, scale);
				glyph.Curves = curves;
				stbtt_FreeShape(fontInfo, vertices);
			}
		}

		// Compute bounding box from actual curve control points.
		// This is more accurate than stbtt_GetGlyphBox because quadratic
		// Bezier curves can extend beyond on-curve endpoints.
		if (glyph.Curves != null && glyph.Curves.Count > 0)
		{
			var minX = float.MaxValue;
			var minY = float.MaxValue;
			var maxX = float.MinValue;
			var maxY = float.MinValue;

			for (let curve in glyph.Curves)
			{
				minX = Math.Min(minX, Math.Min(Math.Min(curve.p1.x, curve.p2.x), curve.p3.x));
				minY = Math.Min(minY, Math.Min(Math.Min(curve.p1.y, curve.p2.y), curve.p3.y));
				maxX = Math.Max(maxX, Math.Max(Math.Max(curve.p1.x, curve.p2.x), curve.p3.x));
				maxY = Math.Max(maxY, Math.Max(Math.Max(curve.p1.y, curve.p2.y), curve.p3.y));
			}

			// Add small padding to avoid edge clipping from float precision
			let pad = (maxX - minX + maxY - minY) * 0.01f;
			glyph.BoundingBox = .(minX - pad, minY - pad, maxX + pad, maxY + pad);
		}
		else
		{
			// No curves - use stbtt box with Y negated
			glyph.BoundingBox = .(
				(float)x0 * scale, (float)(-y1) * scale,
				(float)x1 * scale, (float)(-y0) * scale
			);
		}

		return glyph;
	}

	/// Convert stb_truetype vertex data to quadratic Bézier curves.
	/// stb_truetype outputs: vmove, vline, vcurve (quadratic), vcubic (cubic).
	/// Lines are converted to degenerate quadratic curves (p2 = midpoint).
	/// Cubics are approximated by splitting into quadratics.
	/// Y is negated to convert from font space (Y-up) to screen space (Y-down).
	private static QuadraticBezier2D[] ExtractCurves(stbtt_vertex* vertices, int32 count, float scale)
	{
		let curves = scope List<QuadraticBezier2D>();
		var lastPos = Vector2D.Zero;

		for (int32 i = 0; i < count; i++)
		{
			let v = ref vertices[i];
			let vx = (float)v.x * scale;
			let vy = (float)v.y * scale * -1.0f; // Negate Y

			switch ((STBTT_v)v.type)
			{
			case .STBTT_vmove:
				lastPos = .(vx, vy);

			case .STBTT_vline:
				let endPos = Vector2D(vx, vy);
				let midPos = Vector2D(
					(lastPos.x + endPos.x) * 0.5f,
					(lastPos.y + endPos.y) * 0.5f
				);
				curves.Add(.(lastPos, midPos, endPos));
				lastPos = endPos;

			case .STBTT_vcurve:
				let controlPos = Vector2D((float)v.cx * scale, (float)v.cy * scale * -1.0f);
				let endPos = Vector2D(vx, vy);
				curves.Add(.(lastPos, controlPos, endPos));
				lastPos = endPos;

			case .STBTT_vcubic:
				let c1 = Vector2D((float)v.cx * scale, (float)v.cy * scale * -1.0f);
				let c2 = Vector2D((float)v.cx1 * scale, (float)v.cy1 * scale * -1.0f);
				let endPos = Vector2D(vx, vy);
				ApproximateCubicAsQuadratics(lastPos, c1, c2, endPos, curves);
				lastPos = endPos;
			}
		}

		if (curves.Count == 0)
			return null;

		let result = new QuadraticBezier2D[curves.Count];
		curves.CopyTo(result);
		return result;
	}

	/// Approximate a cubic Bézier with 2 quadratic Béziers (split at t=0.5).
	private static void ApproximateCubicAsQuadratics(
		Vector2D p0, Vector2D p1, Vector2D p2, Vector2D p3,
		List<QuadraticBezier2D> outCurves)
	{
		// Split cubic at t=0.5 using de Casteljau
		let m01 = Midpoint(p0, p1);
		let m12 = Midpoint(p1, p2);
		let m23 = Midpoint(p2, p3);
		let m012 = Midpoint(m01, m12);
		let m123 = Midpoint(m12, m23);
		let mid = Midpoint(m012, m123);

		// First half: approximate cubic (p0, m01, m012, mid) as quadratic
		// Best quadratic control point is 0.5*(3*m01 - p0 + 3*m012 - mid)/2
		// Simplified: use midpoint of cubic control points
		let q1 = Vector2D(
			(3.0f * m01.x - p0.x + 3.0f * m012.x - mid.x) * 0.25f,
			(3.0f * m01.y - p0.y + 3.0f * m012.y - mid.y) * 0.25f
		);
		outCurves.Add(.(p0, q1, mid));

		// Second half: approximate cubic (mid, m123, m23, p3) as quadratic
		let q2 = Vector2D(
			(3.0f * m123.x - mid.x + 3.0f * m23.x - p3.x) * 0.25f,
			(3.0f * m123.y - mid.y + 3.0f * m23.y - p3.y) * 0.25f
		);
		outCurves.Add(.(mid, q2, p3));
	}

	private static Vector2D Midpoint(Vector2D a, Vector2D b)
	{
		return .((a.x + b.x) * 0.5f, (a.y + b.y) * 0.5f);
	}
}
