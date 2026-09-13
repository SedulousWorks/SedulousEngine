using System;
using System.Collections;
using Sedulous.RHI;
using astcenc_Beef;
using bc7enc_Beef;
using bcdec_Beef;

namespace Sedulous.Texture.Compression.Tests;

/// The images the cases encode and the decoders they measure against.
///
/// The decoders are DELIBERATELY not the module's own: the block dispatch only ever encodes,
/// so a round trip here goes out through the encoder and back through independent bit packing.
/// A shared misreading of a format cannot pass.
static class CompressionFixtures
{
	/// A deterministic RGBA8 image: smooth channel ramps, which compress, with enough
	/// block local variation that the encoder has real work to do. The CALLER owns it.
	public static List<uint8> MakeImage(uint32 w, uint32 h, bool alpha)
	{
		let pixels = new List<uint8>();
		pixels.Count = (int)w * (int)h * 4;
		for (uint32 y < h)
		{
			for (uint32 x < w)
			{
				let p = &pixels[((int)y * (int)w + (int)x) * 4];
				p[0] = (uint8)((x * 255) / (w - 1));
				p[1] = (uint8)((y * 255) / (h - 1));
				p[2] = (uint8)(((x + y) * 255) / (w + h - 2));
				p[3] = alpha ? (uint8)((x * 255) / (w - 1)) : 255;
			}
		}
		return pixels;
	}

	/// Peak signal to noise ratio in decibels between two RGBA8 buffers, over the first
	/// `channels` channels. Identical buffers report a nominal ceiling rather than infinity.
	public static double Psnr(List<uint8> a, List<uint8> b, int pixels, int channels)
	{
		var sse = 0.0;
		for (int i < pixels)
		{
			for (int c < channels)
			{
				let d = (double)a[i * 4 + c] - (double)b[i * 4 + c];
				sse += d * d;
			}
		}
		if (sse <= 0.0)
			return 99.0;
		let mse = sse / ((double)pixels * channels);
		return 10.0 * Math.Log10((255.0 * 255.0) / mse);
	}

	/// BC1 or BC7 blocks back to a tightly packed RGBA8 image. The CALLER owns the result.
	public static List<uint8> DecodeBc(List<uint8> blocks, uint32 w, uint32 h, TextureFormat format)
	{
		bc7encc_init();
		let outPixels = new List<uint8>();
		outPixels.Count = (int)w * (int)h * 4;

		let blocksX = (w + 3) / 4;
		let blocksY = (h + 3) / 4;
		let blockBytes = (format == .BC1RGBAUnorm) ? 8 : 16;

		uint8[64] tile = .();
		for (uint32 gy < blocksY)
		{
			for (uint32 gx < blocksX)
			{
				let block = &blocks[((int)gy * (int)blocksX + (int)gx) * blockBytes];
				if (format == .BC1RGBAUnorm)
					bc7encc_unpack_bc1(block, &tile, 1);
				else
					bc7encc_unpack_bc7(block, &tile);

				for (uint32 py < 4)
				{
					let sy = gy * 4 + py;
					if (sy >= h)
						break;
					for (uint32 px < 4)
					{
						let sx = gx * 4 + px;
						if (sx >= w)
							break;
						let d = &outPixels[((int)sy * (int)w + (int)sx) * 4];
						let s = &tile[((int)py * 4 + (int)px) * 4];
						d[0] = s[0];
						d[1] = s[1];
						d[2] = s[2];
						d[3] = s[3];
					}
				}
			}
		}
		return outPixels;
	}

	/// ASTC 4x4 blocks back to RGBA8, through astcenc's own decoder. Empty on any error, and
	/// the CALLER owns the result.
	public static List<uint8> DecodeAstc(List<uint8> blocks, uint32 w, uint32 h, bool srgb)
	{
		let outPixels = new List<uint8>();

		AstcConfig config = .();
		let profile = srgb ? AstcProfile.LdrSrgb : AstcProfile.Ldr;
		if (astcenc_config_init(profile, 4, 4, 1, ASTCENC_PRE_MEDIUM, 0, &config) != .Success)
			return outPixels;

		void* context = null;
		if (astcenc_context_alloc(&config, 1, &context, null) != .Success)
			return outPixels;
		defer astcenc_context_free(context);

		outPixels.Count = (int)w * (int)h * 4;
		void* slice = &outPixels[0];
		AstcImage image = .() { DimX = w, DimY = h, DimZ = 1, DataType = .U8, Data = &slice };
		var swizzle = AstcSwizzle.Identity;

		if (astcenc_decompress_image(context, &blocks[0], (uint)blocks.Count, &image, &swizzle, 0)
			!= .Success)
		{
			outPixels.Clear();
		}
		return outPixels;
	}

	/// BC6H unsigned blocks back to tightly packed RGB floats, three per texel rather than
	/// four, BC6H having no alpha. The CALLER owns the result.
	public static List<float> DecodeBc6h(List<uint8> blocks, uint32 w, uint32 h)
	{
		let outPixels = new List<float>();
		outPixels.Count = (int)w * (int)h * 3;

		let blocksX = (w + 3) / 4;
		let blocksY = (h + 3) / 4;
		var offset = 0;
		float[16 * 3] tile = .();
		for (uint32 y < blocksY)
		{
			for (uint32 x < blocksX)
			{
				bcdec_bc6h_float(&blocks[offset], &tile, 4 * 3, 0);
				offset += 16;
				for (uint32 ty < 4)
				{
					for (uint32 tx < 4)
					{
						let px = x * 4 + tx;
						let py = y * 4 + ty;
						if ((px >= w) || (py >= h))
							continue;
						let s = &tile[((int)ty * 4 + (int)tx) * 3];
						let d = &outPixels[((int)py * (int)w + (int)px) * 3];
						d[0] = s[0];
						d[1] = s[1];
						d[2] = s[2];
					}
				}
			}
		}
		return outPixels;
	}

	/// The worst RELATIVE error between an RGBA32F source and an RGB decode. Relative rather
	/// than absolute because radiance spans decades: an absolute bound would be meaningless at
	/// one end of the range and unreachable at the other.
	public static float MaxRelativeError(List<float> rgba, List<float> rgb, uint32 w, uint32 h)
	{
		var worst = 0.0f;
		for (int i < (int)w * (int)h)
		{
			for (int c < 3)
			{
				let a = rgba[i * 4 + c];
				let b = rgb[i * 3 + c];
				let denominator = (a > 1.0e-3f) ? a : 1.0e-3f;
				let relative = Math.Abs(a - b) / denominator;
				if (relative > worst)
					worst = relative;
			}
		}
		return worst;
	}
}
