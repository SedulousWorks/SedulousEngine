using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// ByteSizeText: a size for a person, in KB below a megabyte and MB to a tenth above.
class ByteSizeTextTests
{
	[Test]
	public static void ASizeIsKilobytesBelowAMegabyteAndMegabytesToATenthAbove()
	{
		Test.Assert(ByteSizeText(0, .. scope .()) == "1 KB", "never 0 KB");
		Test.Assert(ByteSizeText(115461, .. scope .()) == "113 KB");
		Test.Assert(ByteSizeText(421504, .. scope .()) == "412 KB");
		Test.Assert(ByteSizeText(1024 * 1024, .. scope .()) == "1.0 MB");
		Test.Assert(ByteSizeText(7549747, .. scope .()) == "7.2 MB");

		// Appended: what the text held stays in front.
		let line = scope String("Downloading ");
		ByteSizeText(2048, line);
		Test.Assert(line == "Downloading 2 KB");
	}
}
