using System;
using astcenc_Beef;

namespace astcenc_Beef_Test;

/// Drives the binding end to end against the real library: encode an RGBA8 image to ASTC 4x4,
/// decode it back through the same context, and check the result is the image that went in.
///
/// A round trip rather than golden bytes: the encoder is heuristic and an upstream bump may
/// legitimately pick different block modes, but an image that decodes back to something else
/// is a broken binding whatever the version. It also proves the struct layouts line up, which
/// is the risk in binding a C header by hand.
class Program
{
	const uint32 cWidth = 16;
	const uint32 cHeight = 16;

	static int Run()
	{
		// A smooth two axis gradient, which ASTC reproduces closely, over an opaque alpha.
		let source = scope uint8[cWidth * cHeight * 4];
		for (uint32 y < cHeight)
		{
			for (uint32 x < cWidth)
			{
				let i = (y * cWidth + x) * 4;
				source[i + 0] = (uint8)(x * 16);
				source[i + 1] = (uint8)(y * 16);
				source[i + 2] = 64;
				source[i + 3] = 255;
			}
		}

		AstcConfig config = .();
		var status = astcenc_config_init(.Ldr, 4, 4, 1, ASTCENC_PRE_MEDIUM, 0, &config);
		if (status != .Success)
		{
			Console.WriteLine("FAIL: config init said {}", StringView(astcenc_get_error_string(status)));
			return 1;
		}
		// The header's own defaults reaching the Beef struct is the layout check: a shifted
		// field would leave the block size somewhere other than where it was asked for.
		if ((config.BlockX != 4) || (config.BlockY != 4) || (config.BlockZ != 1))
		{
			Console.WriteLine("FAIL: the config came back with block {}x{}x{}, so the struct layout is wrong",
				config.BlockX, config.BlockY, config.BlockZ);
			return 1;
		}

		void* context = null;
		status = astcenc_context_alloc(&config, 1, &context, null);
		if (status != .Success)
		{
			Console.WriteLine("FAIL: context alloc said {}", StringView(astcenc_get_error_string(status)));
			return 1;
		}
		defer astcenc_context_free(context);

		// One 4x4 block is sixteen bytes, and the image is an exact multiple of the block.
		let blocks = ((cWidth + 3) / 4) * ((cHeight + 3) / 4);
		let encoded = scope uint8[blocks * 16];

		void* slice = &source[0];
		AstcImage image = .() { DimX = cWidth, DimY = cHeight, DimZ = 1, DataType = .U8,
			Data = &slice };
		var swizzle = AstcSwizzle.Identity;

		status = astcenc_compress_image(context, &image, &swizzle, &encoded[0],
			(uint)encoded.Count, 0);
		if (status != .Success)
		{
			Console.WriteLine("FAIL: compress said {}", StringView(astcenc_get_error_string(status)));
			return 1;
		}

		let decoded = scope uint8[cWidth * cHeight * 4];
		void* decodedSlice = &decoded[0];
		AstcImage back = .() { DimX = cWidth, DimY = cHeight, DimZ = 1, DataType = .U8,
			Data = &decodedSlice };

		astcenc_decompress_reset(context);
		status = astcenc_decompress_image(context, &encoded[0], (uint)encoded.Count, &back,
			&swizzle, 0);
		if (status != .Success)
		{
			Console.WriteLine("FAIL: decompress said {}", StringView(astcenc_get_error_string(status)));
			return 1;
		}

		var worst = 0;
		for (int i < decoded.Count)
		{
			let d = Math.Abs((int)source[i] - (int)decoded[i]);
			if (d > worst)
				worst = d;
		}
		Console.WriteLine("ASTC 4x4 worst channel delta over {} blocks: {}", blocks, worst);
		if (worst > 16)
		{
			Console.WriteLine("FAIL: ASTC did not reproduce the gradient");
			return 1;
		}

		Console.WriteLine("astcenc-Beef: the image round tripped.");
		return 0;
	}

	public static int Main(String[] args) => Run();
}
