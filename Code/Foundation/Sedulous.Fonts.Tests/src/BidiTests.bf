using System;
using System.Collections;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

/// Laying a line out in visual runs from its levels: UAX #9 rules L1 and L2.
class BidiTests
{
	private static void Fill(BidiLevels levels, Span<uint8> values)
	{
		levels.Levels.Clear();
		for (let value in values)
			levels.Levels.Add(value);
	}

	[Test]
	public static void ALinesRunsComeOutInVisualOrder()
	{
		let runs = scope List<BidiRun>();

		// Left to right with a right-to-left run inside: the runs stay in place.
		let levels = scope BidiLevels();
		uint32[6] text = .((.)'a', (.)'b', 0x05D0, 0x05D1, 0x05D2, (.)'c');
		uint8[6] first = .(0, 0, 1, 1, 1, 0);
		Fill(levels, first);
		Bidi.ReorderLine(levels, text, 0, 6, runs);
		Test.Assert(runs.Count == 3);
		Test.Assert(runs[0].Start == 0);
		Test.Assert(runs[1].Start == 2);
		Test.Assert(runs[1].RightToLeft);
		Test.Assert(runs[2].Start == 5);

		// A right-to-left paragraph (level 1) with a left-to-right run (level 2) inside: the whole
		// line reverses, the inner run reversed back.
		let rightToLeft = scope BidiLevels();
		rightToLeft.ParagraphLevel = 1;
		uint8[5] second = .(1, 1, 2, 2, 1);
		Fill(rightToLeft, second);
		uint32[5] mixed = .(0x05D0, (.)' ', (.)'a', (.)'b', 0x05D1);
		Bidi.ReorderLine(rightToLeft, mixed, 0, 5, runs);
		Test.Assert(runs.Count == 3);
		Test.Assert(runs[0].Start == 4, "the last character, leftmost");
		Test.Assert(runs[1].Start == 2);
		Test.Assert(!runs[1].RightToLeft);
		Test.Assert(runs[2].Start == 0);

		// L1: a line's trailing space takes the paragraph's level.
		let trailing = scope BidiLevels();
		uint8[3] third = .(1, 1, 1);
		Fill(trailing, third);
		uint32[3] spaced = .(0x05D0, 0x05D1, (.)' ');
		Bidi.ReorderLine(trailing, spaced, 0, 3, runs);
		Test.Assert(runs.Count == 2);
		Test.Assert(runs[1].Start == 2, "the space, at level 0, stays on the right");
		Test.Assert(!runs[1].RightToLeft);
	}
}
