using System;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

class FontMetricsTests
{
	[Test]
	static void TestFontMetricsConstructor()
	{
		let metrics = FontMetrics(20.0f, -5.0f, 2.0f, 24.0f, 0.5f);

		Test.Assert(metrics.Ascent == 20.0f);
		Test.Assert(metrics.Descent == -5.0f);
		Test.Assert(metrics.LineGap == 2.0f);
		Test.Assert(metrics.PixelHeight == 24.0f);
		Test.Assert(metrics.Scale == 0.5f);
	}

	[Test]
	static void TestFontMetricsLineHeight()
	{
		let metrics = FontMetrics(20.0f, -5.0f, 2.0f, 24.0f, 0.5f);

		// LineHeight = Ascent - Descent + LineGap = 20 - (-5) + 2 = 27
		Test.Assert(metrics.LineHeight == 27.0f);
	}

	[Test]
	static void TestFontMetricsDefault()
	{
		let metrics = FontMetrics.Default;

		Test.Assert(metrics.Ascent == 0);
		Test.Assert(metrics.Descent == 0);
		Test.Assert(metrics.LineGap == 0);
		Test.Assert(metrics.LineHeight == 0);
		Test.Assert(metrics.Scale == 1.0f);
	}
}
