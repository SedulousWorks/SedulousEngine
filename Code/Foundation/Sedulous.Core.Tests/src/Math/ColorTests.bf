using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Raptor's "color: pack/unpack and operations" case, plus the clamping, the Rgb helper
/// and addition, which it does not reach.
class ColorTests
{
	[Test]
	public static void PackUnpackAndOperations()
	{
		Test.Assert(Color.White.ToRGBA8() == 0xFFFFFFFF);
		Test.Assert(Color.Red.ToRGBA8() == 0xFF0000FF);
		Test.Assert(Color.Transparent.ToRGBA8() == 0x00000000);

		let c = Color.FromRGBA8(0xFF0000FF);
		Test.Assert(NearlyEqual(c, Color.Red));

		Test.Assert(NearlyEqual(Lerp(Color.Black, Color.White, 0.5f),
			Color(0.5f, 0.5f, 0.5f, 1.0f)));
		Test.Assert(NearlyEqual(Color.White * 0.25f, Color(0.25f, 0.25f, 0.25f, 0.25f)));

		// Round-trips through 8-bit packing, within quantization tolerance.
		let original = Color(0.2f, 0.4f, 0.6f, 0.8f);
		Test.Assert(NearlyEqual(Color.FromRGBA8(original.ToRGBA8()), original, 1.0f / 255.0f));
	}

	/// The channel order is the thing a packing routine gets wrong silently. Every
	/// channel is given a distinct value so a transposition cannot pass.
	[Test]
	public static void PackingPutsChannelsInRGBAOrder()
	{
		let c = Color.Rgb(0x11, 0x22, 0x33, 0x44);
		Test.Assert(c.ToRGBA8() == 0x11223344);

		let back = Color.FromRGBA8(0x11223344);
		Test.Assert(NearlyEqual(back, c, 1.0f / 255.0f));

		// Green alone occupies the second byte.
		Test.Assert(Color.Green.ToRGBA8() == 0x00FF00FF);
		Test.Assert(Color.Blue.ToRGBA8() == 0x0000FFFF);
		Test.Assert(Color.Black.ToRGBA8() == 0x000000FF);
	}

	/// ToRGBA8 clamps rather than wrapping. An HDR colour above 1 must saturate, and a
	/// negative one must floor at zero, or the byte cast wraps into a wrong channel.
	[Test]
	public static void PackingClampsOutOfRangeComponents()
	{
		let overbright = Color(2.0f, 1.5f, 1.0f, 1.0f);
		Test.Assert(overbright.ToRGBA8() == 0xFFFFFFFF);

		let negative = Color(-1.0f, -0.5f, 0.0f, 1.0f);
		Test.Assert(negative.ToRGBA8() == 0x000000FF);
	}

	[Test]
	public static void RgbHelperAndAddition()
	{
		Test.Assert(NearlyEqual(Color.Rgb(255, 0, 0), Color.Red));
		Test.Assert(NearlyEqual(Color.Rgb(0, 0, 0, 0), Color.Transparent));
		// The alpha default is opaque.
		Test.Assert(NearlyEqual(Color.Rgb(0, 0, 0), Color.Black));

		Test.Assert(NearlyEqual(Color(0.25f, 0.0f, 0.0f, 0.0f) + Color(0.25f, 0.5f, 0.0f, 1.0f),
			Color(0.5f, 0.5f, 0.0f, 1.0f)));
	}

	[Test]
	public static void LerpEndpoints()
	{
		Test.Assert(NearlyEqual(Lerp(Color.Black, Color.White, 0.0f), Color.Black));
		Test.Assert(NearlyEqual(Lerp(Color.Black, Color.White, 1.0f), Color.White));
		// Alpha interpolates too, which a three-channel Lerp would miss.
		Test.Assert(NearlyEqual(Lerp(Color.Transparent, Color.White, 0.5f),
			Color(0.5f, 0.5f, 0.5f, 0.5f)));
	}

	/// The default alpha is opaque, so a default-constructed Color is black rather than
	/// invisible.
	[Test]
	public static void DefaultIsOpaqueBlack()
	{
		Color c = .();
		Test.Assert(NearlyEqual(c, Color.Black));
		Test.Assert(c.a == 1.0f);
	}
}
