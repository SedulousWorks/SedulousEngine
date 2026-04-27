using System;
using System.Collections;

namespace Sedulous.Slug;

/// Builds the curve texture and band texture from glyph Bézier curve data.
/// This is the core of the Slug algorithm's CPU-side work.
///
/// Curve texture: RGBA16F or RGBA32F, stores Bézier control points.
///   Each curve occupies 2 texels: (p1.x, p1.y, p2.x, p2.y) then (p3.x, p3.y, 0, 0)
///
/// Band texture: RGBA16UI, spatial acceleration structure.
///   Maps horizontal/vertical "bands" to the curves that intersect them.
///   Enables the pixel shader to only test relevant curves per pixel.
public class SlugTextureBuilder
{
	/// Result of building textures for a font.
	public struct BuildResult
	{
		/// Curve texture pixel data (RGBA16F = 8 bytes/texel, or RGBA32F = 16 bytes/texel).
		public uint8[] CurveTextureData;
		/// Band texture pixel data (RGBA16UI = 8 bytes/texel).
		public uint8[] BandTextureData;
		/// Curve texture dimensions.
		public Integer2D CurveTextureSize;
		/// Band texture dimensions.
		public Integer2D BandTextureSize;
		/// Curve texture format.
		public TextureType CurveTextureType;
	}

	private const int32 kTextureWidth = SlugConstants.kBandTextureWidth; // 4096

	/// Build curve and band textures for all glyphs in a font.
	/// This populates the BandLocation/BandCount/BandScale fields on each glyph
	/// and returns the texture data ready for GPU upload.
	public static Result<BuildResult> Build(SlugFont font, int32 maxBandCount = SlugConstants.kMaxBandCount)
	{
		// Phase 1: Calculate total texture space needed
		var totalCurveTexels = 0;
		var totalBandTexels = 0;

		let glyphList = scope List<SlugGlyphData>();
		for (let glyph in font.Glyphs)
		{
			if (!glyph.HasCurves)
				continue;
			glyphList.Add(glyph);

			let curveCount = glyph.Curves.Count;
			totalCurveTexels += curveCount * 2; // 2 texels per curve

			// Band count per glyph: match the actual build formula
			let hBands = Math.Min(maxBandCount, Math.Max(1, (int32)curveCount));
			let vBands = hBands;
			// Band header texels + curve index texels per band
			totalBandTexels += hBands + vBands; // headers
			totalBandTexels += (int)curveCount * (hBands + vBands); // worst case: every curve in every band
		}

		if (glyphList.Count == 0)
			return .Err;

		// Allocate textures (RGBA16F for curves = 8 bytes/texel, RGBA16UI for bands = 8 bytes/texel)
		let curveRows = (totalCurveTexels + kTextureWidth - 1) / kTextureWidth + 1;
		let bandRows = (totalBandTexels + kTextureWidth - 1) / kTextureWidth + 1;

		let curveTexSize = Integer2D(kTextureWidth, (int32)curveRows);
		let bandTexSize = Integer2D(kTextureWidth, (int32)bandRows);

		let curveData = new uint8[curveTexSize.x * curveTexSize.y * 8]; // RGBA16F
		let bandData = new uint8[bandTexSize.x * bandTexSize.y * 8]; // RGBA16UI

		// Phase 2: Pack curve data and build band acceleration structure per glyph
		var curveWritePos = Integer2D(0, 0);
		var bandWritePos = Integer2D(0, 0);

		for (let glyph in glyphList)
		{
			let curves = glyph.Curves;
			let curveCount = (int32)curves.Count;
			let bb = ref glyph.BoundingBox;

			// Determine band counts - use more bands for better spatial acceleration.
			// Original Slug uses up to 32 bands. More bands = fewer curves tested per pixel.
			let hBands = (int16)Math.Min(maxBandCount, Math.Max(1, curveCount));
			let vBands = hBands;

			glyph.BandCount = .(vBands, hBands);
			glyph.BandScale = .(
				(float)vBands / Math.Max(bb.Width, 1e-6f),
				(float)hBands / Math.Max(bb.Height, 1e-6f)
			);

			// Record where this glyph's band data starts
			glyph.BandLocation = .((uint16)bandWritePos.x, (uint16)bandWritePos.y);

			// Write curve control points to curve texture
			var glyphCurveStart = curveWritePos;
			for (int32 c = 0; c < curveCount; c++)
			{
				let curve = ref curves[c];
				// Texel 0: (p1.x, p1.y, p2.x, p2.y) as half-floats
				WriteCurveTexel(curveData, curveTexSize, curveWritePos, curve.p1.x, curve.p1.y, curve.p2.x, curve.p2.y);
				AdvanceTexelPos(ref curveWritePos, kTextureWidth);
				// Texel 1: (p3.x, p3.y, 0, 0)
				WriteCurveTexel(curveData, curveTexSize, curveWritePos, curve.p3.x, curve.p3.y, 0, 0);
				AdvanceTexelPos(ref curveWritePos, kTextureWidth);
			}

			// Build horizontal bands: for each band, find which curves intersect it
			let bandHeaderStart = bandWritePos;
			// Reserve space for band headers (hBands for horizontal + vBands for vertical)
			var curveListStart = bandWritePos;
			curveListStart.x += hBands + vBands; // skip past all headers
			WrapTexelPos(ref curveListStart, kTextureWidth);

			// Epsilon overlap for band boundaries - prevents curves at exact
			// band edges from being missed (per Slug tips: use 1/1024 em-space).
			let bandEpsilon = 1.0f / 1024.0f;

			// Horizontal bands
			for (int16 b = 0; b < hBands; b++)
			{
				let bandMinY = bb.min.y + (float)b / (float)hBands * bb.Height - bandEpsilon;
				let bandMaxY = bb.min.y + (float)(b + 1) / (float)hBands * bb.Height + bandEpsilon;

				// Find curves intersecting this horizontal band.
				// Skip straight horizontal lines - they can't contribute to winding
				// for horizontal rays (parallel to the line).
				let curvesInBand = scope List<int32>();
				for (int32 c = 0; c < curveCount; c++)
				{
					let curve = ref curves[c];
					if (IsHorizontalLine(curve))
						continue;
					let minY = Math.Min(Math.Min(curve.p1.y, curve.p2.y), curve.p3.y);
					let maxY = Math.Max(Math.Max(curve.p1.y, curve.p2.y), curve.p3.y);
					if (maxY >= bandMinY && minY <= bandMaxY)
						curvesInBand.Add(c);
				}

				// Sort by descending max X for early exit optimization
				curvesInBand.Sort(scope (a, b) => {
					let ca = ref curves[a];
					let cb = ref curves[b];
					let maxXA = Math.Max(Math.Max(ca.p1.x, ca.p2.x), ca.p3.x);
					let maxXB = Math.Max(Math.Max(cb.p1.x, cb.p2.x), cb.p3.x);
					return maxXB <=> maxXA;
				});

				// Write band header: (curveCount, offsetToCurveList)
				let headerPos = Integer2D(bandHeaderStart.x + b, bandHeaderStart.y);
				var wrappedHeader = headerPos;
				WrapTexelPos(ref wrappedHeader, kTextureWidth);
				let listOffset = (uint16)(curveListStart.x - bandHeaderStart.x + (curveListStart.y - bandHeaderStart.y) * kTextureWidth);
				WriteBandTexel(bandData, bandTexSize, wrappedHeader, (uint16)curvesInBand.Count, listOffset, 0, 0);

				// Write curve indices for this band
				for (let curveIdx in curvesInBand)
				{
					// Location of curve in curve texture: glyphCurveStart + curveIdx * 2
					var curveLoc = glyphCurveStart;
					curveLoc.x += curveIdx * 2;
					WrapTexelPos(ref curveLoc, kTextureWidth);
					WriteBandTexel(bandData, bandTexSize, curveListStart, (uint16)curveLoc.x, (uint16)curveLoc.y, 0, 0);
					AdvanceTexelPos(ref curveListStart, kTextureWidth);
				}
			}

			// Vertical bands
			for (int16 b = 0; b < vBands; b++)
			{
				let bandMinX = bb.min.x + (float)b / (float)vBands * bb.Width - bandEpsilon;
				let bandMaxX = bb.min.x + (float)(b + 1) / (float)vBands * bb.Width + bandEpsilon;

				// Skip straight vertical lines - they can't contribute to winding
				// for vertical rays (parallel to the line).
				let curvesInBand = scope List<int32>();
				for (int32 c = 0; c < curveCount; c++)
				{
					let curve = ref curves[c];
					if (IsVerticalLine(curve))
						continue;
					let minX = Math.Min(Math.Min(curve.p1.x, curve.p2.x), curve.p3.x);
					let maxX = Math.Max(Math.Max(curve.p1.x, curve.p2.x), curve.p3.x);
					if (maxX >= bandMinX && minX <= bandMaxX)
						curvesInBand.Add(c);
				}

				// Sort by descending max Y for early exit
				curvesInBand.Sort(scope (a, b) => {
					let ca = ref curves[a];
					let cb = ref curves[b];
					let maxYA = Math.Max(Math.Max(ca.p1.y, ca.p2.y), ca.p3.y);
					let maxYB = Math.Max(Math.Max(cb.p1.y, cb.p2.y), cb.p3.y);
					return maxYB <=> maxYA;
				});

				let headerPos = Integer2D(bandHeaderStart.x + hBands + b, bandHeaderStart.y);
				var wrappedHeader = headerPos;
				WrapTexelPos(ref wrappedHeader, kTextureWidth);
				let listOffset = (uint16)(curveListStart.x - bandHeaderStart.x + (curveListStart.y - bandHeaderStart.y) * kTextureWidth);
				WriteBandTexel(bandData, bandTexSize, wrappedHeader, (uint16)curvesInBand.Count, listOffset, 0, 0);

				for (let curveIdx in curvesInBand)
				{
					var curveLoc = glyphCurveStart;
					curveLoc.x += curveIdx * 2;
					WrapTexelPos(ref curveLoc, kTextureWidth);
					WriteBandTexel(bandData, bandTexSize, curveListStart, (uint16)curveLoc.x, (uint16)curveLoc.y, 0, 0);
					AdvanceTexelPos(ref curveListStart, kTextureWidth);
				}
			}

			bandWritePos = curveListStart;
		}

		font.TexturesBuilt = true;

		BuildResult result = .();
		result.CurveTextureData = curveData;
		result.BandTextureData = bandData;
		result.CurveTextureSize = curveTexSize;
		result.BandTextureSize = bandTexSize;
		result.CurveTextureType = .Float16;

		return .Ok(result);
	}

	/// Write a curve texture texel (4x float16 = 8 bytes).
	private static void WriteCurveTexel(uint8[] data, Integer2D texSize, Integer2D pos, float v0, float v1, float v2, float v3)
	{
		let index = (pos.y * texSize.x + pos.x) * 8;
		if (index + 8 > data.Count)
			return;

		let ptr = (uint16*)(void*)(data.Ptr + index);
		ptr[0] = FloatToHalf(v0);
		ptr[1] = FloatToHalf(v1);
		ptr[2] = FloatToHalf(v2);
		ptr[3] = FloatToHalf(v3);
	}

	/// Write a band texture texel (4x uint16 = 8 bytes).
	private static void WriteBandTexel(uint8[] data, Integer2D texSize, Integer2D pos, uint16 v0, uint16 v1, uint16 v2, uint16 v3)
	{
		let index = (pos.y * texSize.x + pos.x) * 8;
		if (index + 8 > data.Count)
			return;

		let ptr = (uint16*)(void*)(data.Ptr + index);
		ptr[0] = v0;
		ptr[1] = v1;
		ptr[2] = v2;
		ptr[3] = v3;
	}

	/// Advance texel position by 1, wrapping to next row at texture width.
	private static void AdvanceTexelPos(ref Integer2D pos, int32 width)
	{
		pos.x++;
		if (pos.x >= width)
		{
			pos.x = 0;
			pos.y++;
		}
	}

	/// Wrap texel position if x exceeds width.
	private static void WrapTexelPos(ref Integer2D pos, int32 width)
	{
		if (pos.x >= width)
		{
			pos.y += pos.x / width;
			pos.x = pos.x % width;
		}
	}

	/// Convert float32 to float16 (IEEE 754 half-precision).
	public static uint16 FloatToHalf(float value)
	{
		var v = value;
		let bits = *(uint32*)&v;
		let sign = (bits >> 16) & 0x8000;
		let exponent = (int32)((bits >> 23) & 0xFF) - 127 + 15;
		let mantissa = bits & 0x007FFFFF;

		if (exponent <= 0)
		{
			if (exponent < -10)
				return (uint16)sign;
			let m = (mantissa | 0x00800000) >> (1 - exponent);
			return (uint16)(sign | (m >> 13));
		}
		else if (exponent == 0xFF - 127 + 15)
		{
			if (mantissa == 0)
				return (uint16)(sign | 0x7C00); // Inf
			return (uint16)(sign | 0x7C00 | (mantissa >> 13)); // NaN
		}
		else if (exponent > 30)
		{
			return (uint16)(sign | 0x7C00); // Overflow -> Inf
		}

		return (uint16)(sign | ((uint32)exponent << 10) | (mantissa >> 13));
	}

	/// Check if a curve is a straight horizontal line (all Y coordinates equal).
	/// These curves can't contribute to winding for horizontal rays.
	private static bool IsHorizontalLine(QuadraticBezier2D curve)
	{
		let eps = 1e-6f;
		return Math.Abs(curve.p1.y - curve.p2.y) < eps &&
			   Math.Abs(curve.p2.y - curve.p3.y) < eps;
	}

	/// Check if a curve is a straight vertical line (all X coordinates equal).
	/// These curves can't contribute to winding for vertical rays.
	private static bool IsVerticalLine(QuadraticBezier2D curve)
	{
		let eps = 1e-6f;
		return Math.Abs(curve.p1.x - curve.p2.x) < eps &&
			   Math.Abs(curve.p2.x - curve.p3.x) < eps;
	}
}
