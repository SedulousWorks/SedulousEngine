using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Raptor's "color32: packed byte color and conversions" case. The sRGB transfer
/// functions and ToLinear are not covered by Raptor at all.
class Color32Tests
{
	[Test]
	public static void PackedByteColorAndConversions()
	{
		Test.Assert(Color32.White.ToRGBA8() == 0xFFFFFFFF);
		Test.Assert(Color32.Red.ToRGBA8() == 0xFF0000FF);
		Test.Assert(Color32.Transparent.ToRGBA8() == 0x00000000);
		Test.Assert(Color32.FromRGBA8(0x10203040) == Color32(0x10, 0x20, 0x30, 0x40));

		// Float and byte conversions, with no gamma applied.
		Test.Assert(ToColor32(Color.Red) == Color32.Red);
		Test.Assert(NearlyEqual(ToColor(Color32.Blue), Color.Blue));
	}

	/// Every byte value has to survive Color32 -> Color -> Color32 exactly, or stored
	/// pixels drift each time they are read and written.
	[Test]
	public static void EveryByteValueRoundTripsExactly()
	{
		for (uint32 v = 0; v <= 255; v++)
		{
			let c = Color32((uint8)v, (uint8)(255 - v), (uint8)v, 255);
			Test.Assert(ToColor32(ToColor(c)) == c);
		}
	}

	/// ToColor32 rounds rather than truncating. Every value that came from a byte is
	/// exactly representable, so the round-trip test above cannot tell the two apart;
	/// a colour that lands between byte values can.
	[Test]
	public static void ToColor32RoundsRatherThanTruncating()
	{
		// 0.5 * 255 = 127.5, which rounds to 128 and truncates to 127.
		Test.Assert(ToColor32(Color(0.5f, 0.5f, 0.5f, 0.5f)).R == 128);
		// Just under a byte boundary still rounds up.
		Test.Assert(ToColor32(Color(0.999f, 0.0f, 0.0f, 1.0f)).R == 255);
		// And just over the previous one does not.
		Test.Assert(ToColor32(Color(1.4f / 255.0f, 0.0f, 0.0f, 1.0f)).R == 1);
	}

	/// ToColor maps alpha linearly, like every other channel. Raptor only converts
	/// colours whose alpha is 255, where any transfer function is the identity, so the
	/// alpha path is untested there.
	[Test]
	public static void ToColorMapsAlphaLinearly()
	{
		let c = ToColor(Color32(10, 20, 30, 128));
		Test.Assert(NearlyEqual(c.A, 128.0f / 255.0f, 1.0e-6f));
		Test.Assert(NearlyEqual(c.R, 10.0f / 255.0f, 1.0e-6f));
		Test.Assert(NearlyEqual(c.G, 20.0f / 255.0f, 1.0e-6f));
		Test.Assert(NearlyEqual(c.B, 30.0f / 255.0f, 1.0e-6f));

		// Half alpha is half, not the curve's value for it.
		Test.Assert(c.A > 0.49f);
	}

	/// The default alpha is opaque, matching Color.
	[Test]
	public static void DefaultIsOpaqueBlack()
	{
		Color32 c = .();
		Test.Assert(c == Color32.Black);
		Test.Assert(c.A == 255);
	}

	/// The sRGB EOTF is piecewise: a linear segment below the knee and a power curve
	/// above it. Getting the knee wrong is invisible in the midtones and wrong in the
	/// darks, which is where banding shows.
	[Test]
	public static void SrgbTransferFunctionsAtTheirEndpointsAndKnee()
	{
		Test.Assert(NearlyEqual(SrgbToLinear(0.0f), 0.0f));
		Test.Assert(NearlyEqual(SrgbToLinear(1.0f), 1.0f, 1.0e-5f));
		Test.Assert(NearlyEqual(LinearToSrgb(0.0f), 0.0f));
		Test.Assert(NearlyEqual(LinearToSrgb(1.0f), 1.0f, 1.0e-5f));

		// The two segments agree at the knee, so the curve is continuous there.
		let kneeSrgb = 0.04045f;
		Test.Assert(NearlyEqual(SrgbToLinear(kneeSrgb), kneeSrgb / 12.92f, 1.0e-6f));

		// Below the knee it is exactly linear.
		Test.Assert(NearlyEqual(SrgbToLinear(0.02f), 0.02f / 12.92f, 1.0e-6f));
		Test.Assert(NearlyEqual(LinearToSrgb(0.002f), 0.002f * 12.92f, 1.0e-6f));

		// Above the knee it is not: mid grey darkens noticeably, which is the whole
		// point of decoding before blending.
		Test.Assert(SrgbToLinear(0.5f) < 0.25f);
		Test.Assert(NearlyEqual(SrgbToLinear(0.5f), 0.21404f, 1.0e-4f));
	}

	/// The two directions are inverses across the whole range, including through the
	/// knee where a mismatched pair would diverge.
	[Test]
	public static void SrgbAndLinearAreInverses()
	{
		float[?] samples = .(0.0f, 0.001f, 0.0031308f, 0.01f, 0.04045f, 0.1f, 0.5f, 0.9f, 1.0f);
		for (let s in samples)
		{
			Test.Assert(NearlyEqual(LinearToSrgb(SrgbToLinear(s)), s, 1.0e-4f));
			Test.Assert(NearlyEqual(SrgbToLinear(LinearToSrgb(s)), s, 1.0e-4f));
		}
	}

	/// ToLinear decodes RGB but leaves alpha alone. Alpha is a coverage fraction, not a
	/// colour, so gamma-decoding it would make everything translucent wrong.
	[Test]
	public static void ToLinearLeavesAlphaAlone()
	{
		let half = Color32(128, 128, 128, 128);
		let linear = ToLinear(half);

		// Alpha is the plain 0..255 to 0..1 mapping.
		Test.Assert(NearlyEqual(linear.A, 128.0f / 255.0f, 1.0e-6f));
		// RGB went through the curve, so it is well below the alpha value.
		Test.Assert(linear.R < linear.A);
		Test.Assert(NearlyEqual(linear.R, SrgbToLinear(128.0f / 255.0f), 1.0e-6f));

		// The endpoints are unmoved.
		Test.Assert(NearlyEqual(ToLinear(Color32.White), Color.White, 1.0e-5f));
		Test.Assert(NearlyEqual(ToLinear(Color32.Black), Color.Black, 1.0e-5f));
	}
}
