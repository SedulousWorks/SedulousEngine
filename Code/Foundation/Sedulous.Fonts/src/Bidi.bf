using System;
using System.Collections;

namespace Sedulous.Fonts;

/// A paragraph's resolved embedding levels, one per character: even reads left to right, odd
/// right to left; the paragraph's own level is its base direction.
class BidiLevels
{
	public List<uint8> Levels = new .() ~ delete _;
	public uint8 ParagraphLevel = 0;
}

/// Characters [Start, End) of a paragraph at one level: a run of a line, in visual order.
struct BidiRun
{
	public int Start;
	public int End;
	public uint8 Level;

	public bool RightToLeft => (Level & 1) != 0;
}

/// Resolves the embedding levels of a paragraph (UAX #9 up to rule I2): the part of the
/// bidirectional algorithm that needs the Unicode data, behind this interface.
abstract class IBidiResolver
{
	/// The levels of one paragraph (no paragraph separator inside), its base direction given,
	/// or (Auto) taken from its first strong character.
	public abstract void Resolve(Span<uint32> codepoints, TextDirection baseDirection, BidiLevels outLevels);
}

/// The process-wide resolver shapers use. A resolver keeps no state between calls, so one
/// instance serves every shaper and thread; its owner installs it and removes it before it goes.
/// Null with none installed: a line is one run in the request's direction.
static class BidiResolverFactory
{
	/// BORROWED: the owner installs and removes it.
	private static IBidiResolver sResolver = null;

	public static void Install(IBidiResolver resolver) => sResolver = resolver;

	public static void Remove(IBidiResolver resolver)
	{
		if (sResolver === resolver)
			sResolver = null;
	}

	public static IBidiResolver Resolver => sResolver;
}

/// Lays a line out in visual runs from its paragraph's levels: rules L1 and L2 of UAX #9,
/// simple enough to keep here rather than behind the resolver.
static class BidiReorder
{
	/// Whitespace for rule L1: a line's trailing whitespace takes the paragraph's level.
	public static bool IsWhitespace(uint32 codepoint)
		=> (codepoint == (uint32)' ') || (codepoint == (uint32)'\t') || (codepoint == 0xA0) || (codepoint == 0x2000)
			|| (codepoint == 0x3000) || ((codepoint >= 0x2001) && (codepoint <= 0x200A));

	/// The visual runs of characters [start, end) of a paragraph: its line's trailing whitespace
	/// at the paragraph level (L1), then every maximal sequence at or above each level reversed,
	/// from the highest level down to the lowest odd one (L2). Runs come out left to right.
	public static void ReorderLine(BidiLevels paragraph, Span<uint32> codepoints, int start, int end,
		List<BidiRun> outRuns)
	{
		outRuns.Clear();
		if ((start >= end) || (end > paragraph.Levels.Count))
			return;

		let levels = scope List<uint8>();
		for (int i = start; i < end; i++)
			levels.Add(paragraph.Levels[i]);
		for (int i = end; (i > start) && ((i - 1) < codepoints.Length) && IsWhitespace(codepoints[i - 1]); i--)
			levels[i - 1 - start] = paragraph.ParagraphLevel;

		// Logical runs of one level.
		uint8 highest = 0;
		uint8 lowestOdd = 0xFF;
		for (int i = 0; i < levels.Count;)
		{
			var j = i + 1;
			while ((j < levels.Count) && (levels[j] == levels[i]))
				j++;
			var run = BidiRun();
			run.Start = start + i;
			run.End = start + j;
			run.Level = levels[i];
			outRuns.Add(run);
			highest = Math.Max(highest, run.Level);
			if ((run.Level & 1) != 0)
				lowestOdd = Math.Min(lowestOdd, run.Level);
			i = j;
		}
		if (lowestOdd == 0xFF)
			return; // all left to right

		for (int level = highest; level >= lowestOdd; level--)
		{
			for (int i = 0; i < outRuns.Count;)
			{
				if (outRuns[i].Level < level)
				{
					i++;
					continue;
				}
				var j = i;
				while ((j < outRuns.Count) && (outRuns[j].Level >= level))
					j++;
				for (int a = i, b = j; (a + 1) < b; a++, b--)
					Swap!(outRuns[a], outRuns[b - 1]);
				i = j;
			}
		}
	}
}
