using System;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

/// Decoding UTF-8 for shaping, and fitting text into a box.
class TextUtilTests
{
	private static uint32 DecodeOne(StringView text)
	{
		int index = 0;
		return DecodeCodepoint(text, ref index);
	}

	[Test]
	public static void EveryUtf8LengthDecodes()
	{
		Test.Assert(DecodeOne("A") == 0x41);
		Test.Assert(DecodeOne("\u{00E9}") == 0xE9, "two bytes");
		Test.Assert(DecodeOne("\u{20AC}") == 0x20AC, "three bytes, the euro sign");
		Test.Assert(DecodeOne("\u{1F600}") == 0x1F600, "four bytes, outside the basic plane");
	}

	/// The index has to come back pointing at the NEXT codepoint, because it is both the
	/// loop's cursor and the byte offset that hit testing reports.
	[Test]
	public static void DecodingAdvancesPastWhatItConsumed()
	{
		let text = "a\u{00E9}\u{20AC}\u{1F600}";
		int index = 0;

		Test.Assert(DecodeCodepoint(text, ref index) == 0x61);
		Test.Assert(index == 1);
		Test.Assert(DecodeCodepoint(text, ref index) == 0xE9);
		Test.Assert(index == 3);
		Test.Assert(DecodeCodepoint(text, ref index) == 0x20AC);
		Test.Assert(index == 6);
		Test.Assert(DecodeCodepoint(text, ref index) == 0x1F600);
		Test.Assert(index == 10);
		Test.Assert(index == text.Length, "and lands exactly on the end");
	}

	/// Malformed input yields the replacement character and always consumes something, so
	/// a caller looping to the end of the string terminates on any bytes at all.
	[Test]
	public static void BrokenSequencesReplaceAndStillAdvance()
	{
		uint8[2] bytes = .(0, 0);

		// A lone continuation byte, which is not the start of anything.
		bytes[0] = 0x80;
		Assert1(bytes, 1);

		// A lead byte announcing two bytes with nothing after it.
		bytes[0] = 0xC3;
		Assert1(bytes, 1);

		// A five byte lead, which UTF-8 has never had.
		bytes[0] = 0xF8;
		Assert1(bytes, 1);

		// A lead byte followed by something that is not a continuation.
		bytes[0] = 0xC3; bytes[1] = 0x41;
		let broken = StringView((char8*)&bytes[0], 2);
		int index = 0;
		Test.Assert(DecodeCodepoint(broken, ref index) == 0xFFFD);
		Test.Assert(index >= 1, "at least one byte is always consumed");
	}

	private static void Assert1(uint8[2] bytes, int length)
	{
		var bytes;
		let text = StringView((char8*)&bytes[0], length);
		int index = 0;
		Test.Assert(DecodeCodepoint(text, ref index) == 0xFFFD);
		Test.Assert(index == 1);
	}

	/// The stub measures 20 per byte, so every expectation below is arithmetic rather than
	/// a guess about a real typeface.
	[Test]
	public static void TextThatFitsIsLeftAlone()
	{
		let font = scope StubFont();
		let text = "A fairly long asset name.png";
		let full = font.MeasureString(text);

		let roomy = scope String();
		TruncateToWidth(font, text, full + 20.0f, roomy);
		Test.Assert(roomy == text);

		let empty = scope String();
		TruncateToWidth(font, "", 100.0f, empty);
		Test.Assert(empty.Length == 0);
	}

	/// A control sized to exactly fit its own label can measure a fraction short once
	/// layout has rounded. Without the tolerance a snug button turns "OK" into "...".
	[Test]
	public static void ASubPixelOverflowIsNotTruncated()
	{
		let font = scope StubFont();
		let text = "A fairly long asset name.png";
		let full = font.MeasureString(text);

		let snug = scope String();
		TruncateToWidth(font, text, full - 0.5f, snug);
		Test.Assert(snug == text);
	}

	[Test]
	public static void TextThatDoesNotFitIsCutAndEllipsised()
	{
		let font = scope StubFont();
		let text = "A fairly long asset name.png";
		let budget = font.MeasureString(text) * 0.5f;

		let cut = scope String();
		TruncateToWidth(font, text, budget, cut);

		Test.Assert(cut.Length < text.Length);
		Test.Assert(cut.EndsWith("..."));
		Test.Assert(font.MeasureString(cut) <= budget, "and the result actually fits");
	}

	/// Replacing something already narrower than the ellipsis makes it WIDER. A "+" button
	/// in a tight box is the case this protects.
	[Test]
	public static void ALabelNarrowerThanTheEllipsisIsLeftAlone()
	{
		let font = scope StubFont();
		let plusWidth = font.MeasureString("+");

		let kept = scope String();
		TruncateToWidth(font, "+", plusWidth * 0.4f, kept);
		Test.Assert(kept == "+");
	}

	/// A box too narrow for even the ellipsis keeps none of the text: there is no width
	/// left to spend on a prefix.
	[Test]
	public static void ABoxNarrowerThanTheEllipsisGetsOnlyTheEllipsis()
	{
		let font = scope StubFont();
		let cut = scope String();
		TruncateToWidth(font, "A fairly long asset name.png", 1.0f, cut);
		Test.Assert(cut == "...");
	}

	/// The cut lands on a codepoint boundary, never inside a multi byte sequence, or the
	/// result is not valid text.
	[Test]
	public static void TheCutLandsOnACodepointBoundary()
	{
		let font = scope StubFont();
		// Three euro signs: three bytes each, so nine bytes measuring 180 by the stub's
		// twenty per byte. The ellipsis costs 60, leaving 60 of budget at width 120.
		let text = "\u{20AC}\u{20AC}\u{20AC}";
		Test.Assert(text.Length == 9);

		let cut = scope String();
		TruncateToWidth(font, text, 120.0f, cut);

		let prefix = cut.Substring(0, cut.Length - 3);
		Test.Assert(prefix.Length % 3 == 0, scope $"cut mid sequence: {prefix.Length} bytes");

		int index = 0;
		while (index < prefix.Length)
			Test.Assert(DecodeCodepoint(prefix, ref index) == 0x20AC, "and every one still decodes");
	}
}
