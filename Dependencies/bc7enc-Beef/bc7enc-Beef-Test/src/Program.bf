using System;
using bc7enc_Beef;

namespace bc7enc_Beef_Test;

/// Drives the binding end to end against the real library: encode a block with every format
/// the wrapper exposes, decode it back, and check the result is the block that went in.
///
/// A round trip rather than golden bytes: the encoders are heuristic and an upstream bump may
/// legitimately pick different endpoints, but a block that decodes back to something else is
/// a broken binding whatever the version.
class Program
{
	/// A 4x4 block of tightly packed RGBA8: a smooth ramp, which every format reproduces
	/// closely, over an opaque alpha.
	static void MakeRamp(uint8* block)
	{
		for (int i < 16)
		{
			let v = (uint8)(i * 17); // 0 to 255 across the block
			block[i * 4 + 0] = v;
			block[i * 4 + 1] = (uint8)(255 - v);
			block[i * 4 + 2] = 128;
			block[i * 4 + 3] = 255;
		}
	}

	/// The largest per channel difference between two RGBA8 blocks.
	static int MaxDelta(uint8* a, uint8* b, int channels)
	{
		var worst = 0;
		for (int texel < 16)
		{
			for (int c < channels)
			{
				let d = Math.Abs((int)a[texel * 4 + c] - (int)b[texel * 4 + c]);
				if (d > worst)
					worst = d;
			}
		}
		return worst;
	}

	static int Run()
	{
		bc7encc_init();

		if (bc7encc_rgbcx_max_level() == 0)
		{
			Console.WriteLine("FAIL: the encoder reports no quality levels at all");
			return 1;
		}
		let level = bc7encc_rgbcx_max_level();

		uint8[64] source = .();
		MakeRamp(&source);
		uint8[64] decoded = .();
		uint8[16] encoded = .();

		// BC1: eight bytes, colour only, so alpha comes back opaque. The tolerance is wide
		// because BC1 spends two endpoints and two selector bits on a full range ramp; what
		// it catches is a binding that returns garbage, which lands near 255.
		bc7encc_encode_bc1(level, &encoded, &source, 1, 0);
		bc7encc_unpack_bc1(&encoded, &decoded, 1);
		var delta = MaxDelta(&source, &decoded, 3);
		Console.WriteLine("BC1 worst channel delta: {}", delta);
		if (delta > 40)
		{
			Console.WriteLine("FAIL: BC1 did not reproduce the ramp");
			return 1;
		}

		// BC3: sixteen bytes, colour plus a real alpha block.
		bc7encc_encode_bc3(level, &encoded, &source);
		bc7encc_unpack_bc3(&encoded, &decoded);
		delta = MaxDelta(&source, &decoded, 4);
		Console.WriteLine("BC3 worst channel delta: {}", delta);
		if (delta > 40)
		{
			Console.WriteLine("FAIL: BC3 did not reproduce the ramp");
			return 1;
		}

		// BC7: sixteen bytes and the best of them, so the tolerance is tight.
		bc7encc_encode_bc7(&encoded, &source, 4);
		if (bc7encc_unpack_bc7(&encoded, &decoded) == 0)
		{
			Console.WriteLine("FAIL: BC7 decoded as an invalid mode");
			return 1;
		}
		delta = MaxDelta(&source, &decoded, 4);
		Console.WriteLine("BC7 worst channel delta: {}", delta);
		if (delta > 8)
		{
			Console.WriteLine("FAIL: BC7 did not reproduce the ramp");
			return 1;
		}

		// BC4: one channel, eight bytes, unpacked at a stride of four so it lands in R. Two
		// endpoints and eight interpolated levels over a sixteen step ramp put the worst
		// texel about half a step out, so the bound sits just above that.
		bc7encc_encode_bc4(&encoded, &source, 4);
		decoded = .();
		bc7encc_unpack_bc4(&encoded, &decoded, 4);
		delta = MaxDelta(&source, &decoded, 1);
		Console.WriteLine("BC4 worst channel delta: {}", delta);
		if (delta > 24)
		{
			Console.WriteLine("FAIL: BC4 did not reproduce the red ramp");
			return 1;
		}

		// BC5: two channels, sixteen bytes.
		bc7encc_encode_bc5(&encoded, &source, 0, 1, 4);
		decoded = .();
		bc7encc_unpack_bc5(&encoded, &decoded, 0, 1, 4);
		delta = MaxDelta(&source, &decoded, 2);
		Console.WriteLine("BC5 worst channel delta: {}", delta);
		if (delta > 24)
		{
			Console.WriteLine("FAIL: BC5 did not reproduce the red and green ramps");
			return 1;
		}

		Console.WriteLine("bc7enc-Beef: every format round tripped.");
		return 0;
	}

	public static int Main(String[] args) => Run();
}
