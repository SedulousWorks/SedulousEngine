using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// OS entropy: draws fill the span and differ, and a Guid from it is version 4 and never
/// repeats; a seeded Guid carries the same tag.
class SystemEntropyTests
{
	/// Version nibble '4' at 14, the RFC 4122 variant (8, 9, a or b) at 19, in the 'D' form.
	private static bool IsVersion4(Guid guid)
	{
		let text = guid.ToString(.. scope .());
		return (text.Length == 36) && (text[14] == '4') && ("89ab".Contains(text[19]));
	}

	[Test]
	public static void DrawsFillTheSpanAndDiffer()
	{
		// Past getentropy's 256 byte cap, so the chunking is exercised: the tail is filled too.
		uint8[300] a = default;
		uint8[300] b = default;
		Test.Assert(SystemEntropy.Fill(a));
		Test.Assert(SystemEntropy.Fill(b));
		bool tailFilled = false;
		for (int i = 256; i < 300; i++)
			tailFilled |= (a[i] != 0);
		Test.Assert(tailFilled, "the bytes past the first chunk are drawn");
		bool differ = false;
		for (int i < 300)
			differ |= (a[i] != b[i]);
		Test.Assert(differ, "two draws differ");
	}

	[Test]
	public static void AnEntropyGuidIsVersion4AndNeverRepeats()
	{
		let seen = scope HashSet<Guid>();
		for (int i < 64)
		{
			Guid guid;
			Test.Assert(Guid.TryGenerateFromSystemEntropy(out guid));
			Test.Assert(IsVersion4(guid), scope $"{guid} is tagged v4");
			Test.Assert(seen.Add(guid), "never repeats");
		}

		var rng = Random(7);
		Test.Assert(IsVersion4(Guid.Generate(ref rng)), "the seeded form carries the same tag");
	}
}
