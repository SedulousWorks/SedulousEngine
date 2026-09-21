using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Integers and strings hash deterministically, and StringHash is a constant identity
/// over UTF-8 text.
class HashingTests
{
	[Test]
	public static void IntegersAndStringsHashDeterministically()
	{
		Test.Assert(HashInteger(42) == HashInteger(42));
		Test.Assert(HashInteger(42) != HashInteger(43));

		Test.Assert(HashText("hello") == HashText("hello"));
		Test.Assert(HashText("hello") != HashText("world"));

		uint8[3] abc = .((uint8)'a', (uint8)'b', (uint8)'c');
		Test.Assert(HashBytes(&abc[0], 3) == HashBytes(&abc[0], 3));
	}

	/// The text path and the byte path are the same function over the same bytes, so a
	/// name hashed as text and the same name hashed as bytes must agree.
	[Test]
	public static void TheTextAndBytePathsAgree()
	{
		let text = "Runtime";
		let hash = StringHash(text);
		Test.Assert(hash.Value == HashBytes(text.Ptr, text.Length));
		Test.Assert(hash.Value == HashText(text));
	}

	[Test]
	public static void AStringHashIsAnIdentity()
	{
		let runtime = StringHash("Runtime");
		let editor = StringHash("Editor");

		Test.Assert(runtime != editor);
		Test.Assert(StringHash("Runtime") == runtime);
		Test.Assert(!StringHash().IsValid, "zero means no value");
		Test.Assert(runtime.IsValid);
	}

	/// Sequential ids are the case the finaliser exists for: without it they land in
	/// sequential buckets, which turns a table into a list exactly when it is fullest.
	[Test]
	public static void TheIntegerFinaliserScattersSequentialKeys()
	{
		let buckets = scope bool[64];
		int distinct = 0;
		for (uint64 i = 0; i < 32; i++)
		{
			let bucket = (int)(HashInteger(i) % 64);
			if (!buckets[bucket])
			{
				buckets[bucket] = true;
				distinct++;
			}
		}
		// Thirty two keys into sixty four buckets collide some of the time by birthday, but
		// a finaliser that did nothing would put them in thirty two ADJACENT buckets and
		// this would still pass; what it catches is one that collapses them.
		Test.Assert(distinct >= 20, scope $"only {distinct} distinct buckets");
	}

	/// Seeding is what lets a caller hash in parts: part two seeded with part one's result
	/// equals hashing the whole.
	[Test]
	public static void SeedingChainsToTheSameAnswer()
	{
		uint8[6] all = .((uint8)'a', (uint8)'b', (uint8)'c', (uint8)'d', (uint8)'e', (uint8)'f');
		let whole = HashBytes(&all[0], 6);
		let firstHalf = HashBytes(&all[0], 3);
		let chained = HashBytes(&all[3], 3, firstHalf);
		Test.Assert(chained == whole);
	}

	[Test]
	public static void AnEmptyTextHashesToTheBasis()
	{
		Test.Assert(HashText("") == FnvOffsetBasis);
		Test.Assert(HashBytes(null, 0) == FnvOffsetBasis);
	}
}
