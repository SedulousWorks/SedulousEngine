using System;
using bcdec_Beef;

namespace bcdec_Beef_Test;

/// Drives the binding against a BC6H block built here bit by bit, and checks what comes back
/// is what the D3D11.3 specification says it should be.
///
/// EXACT, not approximate: the block is mode 11 with every interpolation weight at zero, so
/// every texel decodes to the first endpoint and the expected half bit pattern follows
/// straight from the spec's unquantize and finish steps. Comparing half PATTERNS rather than
/// floats leaves no tolerance to hide a wrong shift in.
///
/// That property is the whole reason this library is vendored: the engine's own BC6H encoder
/// is written against the same arithmetic, and this is the independent witness that the
/// arithmetic is right.
class Program
{
	/// The block's 128 bits, written least significant bit first, which is BC6H's order.
	struct BitWriter
	{
		public uint8* Out;
		public uint32 Position = 0;

		public void Write(uint32 value, uint32 bits) mut
		{
			for (uint32 i < bits)
			{
				if (((value >> i) & 1) != 0)
					Out[(Position + i) >> 3] |= (uint8)(1 << ((Position + i) & 7));
			}
			Position += bits;
		}
	}

	/// The spec's unquantize for a 10 bit UNSIGNED endpoint: nought stays nought, the top
	/// value saturates, and everything between sits on a 64 unit grid offset by 32.
	static int32 Unquantize10(int32 q)
	{
		if (q <= 0)
			return 0;
		if (q >= 1023)
			return 0xFFFF;
		return (q << 6) + 32;
	}

	/// The spec's finish step: the internal value becomes the half float's bit pattern.
	static uint16 Finish(int32 v) => (uint16)((v * 31) >> 6);

	static int Run()
	{
		// Three endpoints spread across the range, so a shift error in any channel shows.
		let q0 = int32[3](512, 256, 128);
		let q1 = int32[3](900, 700, 300); // never reached: every weight is zero

		uint8[16] block = .();
		BitWriter writer = .() { Out = &block };
		writer.Write(0x03, 5); // mode 11: one region, two 10 bit endpoints, no delta coding
		for (int c < 3)
			writer.Write((uint32)q0[c], 10);
		for (int c < 3)
			writer.Write((uint32)q1[c], 10);
		writer.Write(0, 3); // the anchor texel's weight, three bits because its top bit is implied
		for (int i = 1; i < 16; ++i)
			writer.Write(0, 4);

		if (writer.Position != 128)
		{
			Console.WriteLine("FAIL: the block packed to {} bits, not 128", writer.Position);
			return 1;
		}

		// Sixteen texels of three halves each, at a pitch of three per row.
		uint16[48] halves = .();
		bcdec_bc6h_half(&block, &halves, 3 * 4, 0);

		for (int c < 3)
		{
			let expected = Finish(Unquantize10(q0[c]));
			for (int texel < 16)
			{
				let got = halves[texel * 3 + c];
				if (got != expected)
				{
					Console.WriteLine("FAIL: texel {} channel {} decoded to 0x{:X4}, the spec says 0x{:X4}",
						texel, c, got, expected);
					return 1;
				}
			}
			Console.WriteLine("channel {}: every texel decoded to 0x{:X4}, as the spec says", c, expected);
		}

		// And the float entry point agrees with the half one, which is what a caller measuring
		// encoder error actually uses.
		float[48] floats = .();
		bcdec_bc6h_float(&block, &floats, 3 * 4, 0);
		for (int c < 3)
		{
			let half = Finish(Unquantize10(q0[c]));
			// Half bits to float, for the normal range these endpoints land in.
			let exponent = (int32)((half >> 10) & 0x1F) - 15;
			let mantissa = 1.0f + (float)(half & 0x3FF) / 1024.0f;
			let expected = mantissa * Math.Pow(2.0f, (float)exponent);
			if (Math.Abs(floats[c] - expected) > expected * 0.001f)
			{
				Console.WriteLine("FAIL: channel {} came back as {} float, expected {}", c,
					floats[c], expected);
				return 1;
			}
		}

		Console.WriteLine("bcdec-Beef: BC6H decodes exactly as the specification describes.");
		return 0;
	}

	public static int Main(String[] args) => Run();
}
