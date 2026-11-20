using System;
using System.Collections;

namespace Sedulous.Texture.Pipeline;

/// Building a mip chain at cook time.
///
/// The averaging happens in LINEAR space for an sRGB image's colour channels, and it has to: a
/// half black, half white checker averages to linear one half, which is about 188 in sRGB and
/// not 128. Averaging the stored bytes directly darkens every level.
static class TextureMipChain
{
	private static float SrgbToLinearExact(uint8 value)
	{
		let c = (float)value / 255.0f;
		return (c <= 0.04045f) ? (c / 12.92f) : Math.Pow((c + 0.055f) / 1.055f, 2.4f);
	}

	private static uint8 LinearToSrgbExact(float value)
	{
		let c = Math.Clamp(value, 0.0f, 1.0f);
		let encoded = (c <= 0.0031308f) ? (c * 12.92f)
			: (1.055f * Math.Pow(c, 1.0f / 2.4f) - 0.055f);
		return (uint8)(encoded * 255.0f + 0.5f);
	}

	/// The transfer functions as TABLES, built once per chain.
	///
	/// Nine kilobytes and about eight thousand Pow calls to fill, which is nothing beside a
	/// texture, against roughly ninety million evaluations for a 4k chain: the per texel Pow
	/// was most of the sRGB mip cost. Decoding is exact, the input being eight bit; encoding
	/// quantizes linear to one part in 8191 before the exact curve, well under an sRGB code
	/// step everywhere but the first few codes, where it stays within one.
	///
	/// Per chain rather than static, so nothing here is process wide state.
	private class SrgbTables
	{
		public float[256] ToLinear = .();
		public uint8[8192] ToSrgb = .();

		public this()
		{
			for (int i < 256)
				ToLinear[i] = SrgbToLinearExact((uint8)i);
			for (int i < 8192)
				ToSrgb[i] = LinearToSrgbExact((float)i / 8191.0f);
		}

		[Inline]
		public uint8 Encode(float linear)
		{
			let c = Math.Clamp(linear, 0.0f, 1.0f);
			return ToSrgb[(int)(c * 8191.0f + 0.5f)];
		}
	}

	/// Appends every level below the first to `pixels`, which already holds level nought as
	/// tightly packed RGBA8, by a two by two box clamped at an odd edge. Alpha, and everything
	/// in a linear image, averages directly.
	///
	/// With `coverageReference` above 0 (an alpha-tested texture), color averages weighted by
	/// alpha instead, each fully clear texel then takes the color of its texel one level up
	/// (FillClearTexels), and each level's alpha is scaled to keep level nought's coverage of it
	/// (PreserveAlphaCoverage). A texture with no cutoff keeps the plain average: its alpha may
	/// not be opacity at all.
	///
	/// Returns the TOTAL level count, the first one included.
	public static uint32 Append(List<uint8> pixels, uint32 width, uint32 height, bool srgb, float coverageReference = 0.0f)
	{
		let alphaWeighted = coverageReference > 0.0f;
		let levels = AppendBoxChain(pixels, width, height, srgb, alphaWeighted);
		if (alphaWeighted)
		{
			FillClearTexels(pixels, width, height, levels);
			PreserveAlphaCoverage(pixels, width, height, levels, coverageReference);
		}
		return levels;
	}

	/// Gives each fully clear texel of a tight RGBA8 2D chain the color of its texel one level up,
	/// coarsest level first, so every clear texel carries its neighbourhood's visible color. A
	/// clear texel never shows, but filtering blends it into the visible texels beside it: left as
	/// the image's background, it fringes every edge with that color, close up and far.
	public static void FillClearTexels(List<uint8> pixels, uint32 width, uint32 height, uint32 levels)
	{
		if (levels < 2)
			return;
		let offsets = scope int[levels];
		let widths = scope uint32[levels];
		let heights = scope uint32[levels];
		var offset = 0;
		var w = width;
		var h = height;
		for (uint32 level < levels)
		{
			offsets[level] = offset;
			widths[level] = w;
			heights[level] = h;
			offset += (int)w * (int)h * 4;
			w = (w > 1) ? w / 2 : 1;
			h = (h > 1) ? h / 2 : 1;
		}
		for (int level = (int)levels - 2; level >= 0; level--)
		{
			let levelWidth = widths[level];
			let levelHeight = heights[level];
			let parentWidth = widths[level + 1];
			let parentHeight = heights[level + 1];
			let texels = pixels.Ptr + offsets[level];
			let parent = pixels.Ptr + offsets[level + 1];
			for (uint32 y < levelHeight)
			{
				let parentY = Math.Min(y / 2, parentHeight - 1);
				for (uint32 x < levelWidth)
				{
					let texel = texels + ((int)y * (int)levelWidth + (int)x) * 4;
					if (texel[3] != 0)
						continue;
					let from = parent + ((int)parentY * (int)parentWidth + (int)Math.Min(x / 2, parentWidth - 1)) * 4;
					texel[0] = from[0];
					texel[1] = from[1];
					texel[2] = from[2];
				}
			}
		}
	}

	/// Scales the alpha of each level after the first of a tight RGBA8 2D chain (`levels`
	/// levels, level nought `width` x `height`) so the share of its texels at or above
	/// `reference` (0..1, an alpha test's cutoff) is level nought's. The whole chain is built
	/// from unscaled levels first, so no level's scale feeds the next. Per level, the alpha
	/// above which that share of its texels lies (from a histogram) is scaled onto the
	/// reference.
	public static void PreserveAlphaCoverage(List<uint8> pixels, uint32 width, uint32 height, uint32 levels, float reference)
	{
		let cut = (uint32)(Math.Clamp(reference, 0.0f, 1.0f) * 255.0f + 0.5f);
		if ((cut == 0) || (levels < 2))
			return; // everything passes a zero cutoff: nothing to keep
		uint64[256] bins = default;
		void Histogram(int offset, int count)
		{
			for (int b < 256)
				bins[b] = 0;
			for (int i < count)
				bins[pixels[offset + i * 4 + 3]]++;
		}
		let count0 = (int)width * (int)height;
		Histogram(0, count0);
		uint64 passing0 = 0;
		for (uint32 a = cut; a < 256; a++)
			passing0 += bins[a];
		if ((passing0 == 0) || (passing0 == (uint64)count0))
			return; // all or nothing passes: the box chain keeps that already
		let target = (double)passing0 / (double)count0;
		var offset = count0 * 4;
		var w = width;
		var h = height;
		for (uint32 level = 1; level < levels; level++)
		{
			w = (w > 1) ? w / 2 : 1;
			h = (h > 1) ? h / 2 : 1;
			let count = (int)w * (int)h;
			Histogram(offset, count);
			// The alpha above which the target share of this level's texels lies.
			let wanted = (uint64)(target * (double)count + 0.5);
			uint64 seen = 0;
			uint32 threshold = 255;
			while ((threshold > 0) && ((seen + bins[threshold]) < wanted))
			{
				seen += bins[threshold];
				threshold--;
			}
			// Threshold 0 would need texels with no alpha to pass: the level keeps what it has.
			if ((threshold > 0) && (wanted > 0))
			{
				let scale = (float)cut / (float)threshold;
				for (int i < count)
				{
					let at = offset + i * 4 + 3;
					pixels[at] = (uint8)Math.Min(255.0f, (float)pixels[at] * scale + 0.5f);
				}
			}
			offset += count * 4;
		}
	}

	/// The two by two box chain below level nought, appended; the level count. With
	/// `alphaWeighted`, color averages weighted by alpha.
	private static uint32 AppendBoxChain(List<uint8> pixels, uint32 width, uint32 height, bool srgb, bool alphaWeighted)
	{
		let tables = srgb ? scope SrgbTables() : null;
		uint32 levels = 1;
		var sourceOffset = 0;
		var sourceWidth = width;
		var sourceHeight = height;

		while ((sourceWidth > 1) || (sourceHeight > 1))
		{
			let destinationWidth = (sourceWidth > 1) ? sourceWidth / 2 : 1;
			let destinationHeight = (sourceHeight > 1) ? sourceHeight / 2 : 1;
			let destinationOffset = pixels.Count;
			pixels.Count = destinationOffset + (int)destinationWidth * (int)destinationHeight * 4;

			let source = pixels.Ptr + sourceOffset;
			let destination = pixels.Ptr + destinationOffset;

			for (uint32 y < destinationHeight)
			{
				let y0 = y * 2;
				let y1 = ((y0 + 1) < sourceHeight) ? (y0 + 1) : y0; // clamped at an odd edge
				for (uint32 x < destinationWidth)
				{
					let x0 = x * 2;
					let x1 = ((x0 + 1) < sourceWidth) ? (x0 + 1) : x0;

					let p00 = source + ((int)y0 * (int)sourceWidth + (int)x0) * 4;
					let p01 = source + ((int)y0 * (int)sourceWidth + (int)x1) * 4;
					let p10 = source + ((int)y1 * (int)sourceWidth + (int)x0) * 4;
					let p11 = source + ((int)y1 * (int)sourceWidth + (int)x1) * 4;
					let outTexel = destination + ((int)y * (int)destinationWidth + (int)x) * 4;

					// An alpha-tested texture's clear texels hold whatever color its image has
					// round the shapes (often near white): a plain average pulls every smaller
					// level toward it, so distant leaves wash out. Weighted by alpha, a level's
					// color is its visible texels' alone.
					let alphaSum = (uint32)p00[3] + p01[3] + p10[3] + p11[3];
					if (alphaWeighted && (alphaSum > 0))
					{
						let inverse = 1.0f / (float)alphaSum;
						for (int c < 3)
						{
							if (srgb)
							{
								let average = (tables.ToLinear[p00[c]] * p00[3] + tables.ToLinear[p01[c]] * p01[3]
									+ tables.ToLinear[p10[c]] * p10[3] + tables.ToLinear[p11[c]] * p11[3]) * inverse;
								outTexel[c] = tables.Encode(average);
							}
							else
							{
								let average = ((float)p00[c] * p00[3] + (float)p01[c] * p01[3]
									+ (float)p10[c] * p10[3] + (float)p11[c] * p11[3]) * inverse;
								outTexel[c] = (uint8)Math.Min(255.0f, average + 0.5f);
							}
						}
						outTexel[3] = (uint8)((alphaSum + 2) / 4);
						continue;
					}

					for (int c < 4)
					{
						if (srgb && (c < 3))
						{
							let average = (tables.ToLinear[p00[c]] + tables.ToLinear[p01[c]]
								+ tables.ToLinear[p10[c]] + tables.ToLinear[p11[c]]) * 0.25f;
							outTexel[c] = tables.Encode(average);
						}
						else
						{
							outTexel[c] = (uint8)(((uint32)p00[c] + p01[c] + p10[c] + p11[c] + 2) / 4);
						}
					}
				}
			}

			sourceOffset = destinationOffset;
			sourceWidth = destinationWidth;
			sourceHeight = destinationHeight;
			levels++;
		}
		return levels;
	}
}
