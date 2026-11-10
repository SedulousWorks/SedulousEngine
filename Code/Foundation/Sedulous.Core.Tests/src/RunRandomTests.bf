using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// A run's random numbers: a seed replays, the ranges are what the methods promise, and
/// Reset goes back to the default sequence a fresh run starts on.
class RunRandomTests
{
	/// The same seed gives the same draws, of every verb; another seed another sequence.
	[Test]
	public static void ASeedReplays()
	{
		let a = scope RunRandom();
		let b = scope RunRandom();
		a.Seed(7);
		b.Seed(7);
		for (int i < 32)
		{
			Test.Assert(a.Value() == b.Value(), "Value replays");
			Test.Assert(a.Range(-3.0f, 9.0f) == b.Range(-3.0f, 9.0f), "Range replays");
			Test.Assert(a.IntRange(1, 6) == b.IntRange(1, 6), "IntRange replays");
			Test.Assert(a.Bool() == b.Bool(), "Bool replays");
		}

		a.Seed(7);
		b.Seed(8);
		bool differs = false;
		for (int i < 16)
		{
			if (a.NextU32() != b.NextU32())
				differs = true;
		}
		Test.Assert(differs, "another seed, another sequence");
	}

	/// Value is in [0, 1), Range in [min, max), IntRange in [min, max] with both ends drawn,
	/// and an empty IntRange answers its min.
	[Test]
	public static void TheRangesAreTheScriptVerbs()
	{
		let random = scope RunRandom();
		random.Seed(2024);
		bool sawLow = false;
		bool sawHigh = false;
		for (int i < 2000)
		{
			let v = random.Value();
			Test.Assert((v >= 0.0f) && (v < 1.0f), "Value is half open");
			let r = random.Range(-2.0f, 5.0f);
			Test.Assert((r >= -2.0f) && (r < 5.0f), "Range is half open");
			let n = random.IntRange(10, 13);
			Test.Assert((n >= 10) && (n <= 13), "IntRange is inclusive");
			if (n == 10)
				sawLow = true;
			if (n == 13)
				sawHigh = true;
		}
		Test.Assert(sawLow && sawHigh, "both ends of an IntRange are drawn");
		for (int i < 8)
		{
			Test.Assert(random.IntRange(5, 5) == 5, "a one value range is that value");
			Test.Assert(random.IntRange(9, 2) == 9, "an empty range answers its min");
		}
	}

	/// A fresh one draws the default seed's sequence, and Reset after any draws and seeds draws
	/// it again from the start.
	[Test]
	public static void ResetIsTheDefaultSequenceFromTheStart()
	{
		var reference = Random();
		let random = scope RunRandom();
		let first = random.NextU32();
		Test.Assert(first == reference.NextU32(), "the default seed's sequence");

		random.Seed(99);
		random.Value();
		random.IntRange(0, 100);
		random.Reset();
		Test.Assert(random.NextU32() == first, "Reset starts it over");
	}
}
