using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// @keyframes: keyframe blocks parsed into named stops.
class KeyframesTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void ParseNamesOffsetsPercentFromToAndStopDeclarations()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(
			"@keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.25; } 100% { opacity: 1; } }" +
			"@keyframes fade  { from { opacity: 1; } to { opacity: 0; } }", sheet);

		Test.Assert(sheet.KeyframesCount == 2);

		let pulse = sheet.FindKeyframes("pulse");
		Test.Assert(pulse != null);
		Test.Assert(pulse.Stops.Count == 3);
		Test.Assert(Near(pulse.Stops[0].Offset, 0.0f));
		Test.Assert(Near(pulse.Stops[1].Offset, 0.5f));
		Test.Assert(Near(pulse.Stops[2].Offset, 1.0f));
		Test.Assert(pulse.Stops[1].Properties.Count == 1);

		let fade = sheet.FindKeyframes("fade");
		Test.Assert(fade != null);
		Test.Assert(fade.Stops.Count == 2);
		Test.Assert(Near(fade.Stops[0].Offset, 0.0f)); // from
		Test.Assert(Near(fade.Stops[1].Offset, 1.0f)); // to
	}

	[Test]
	public static void ACommaOffsetListSharesTheBlock()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse("@keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0; } }", sheet);
		let blink = sheet.FindKeyframes("blink");
		Test.Assert(blink != null);
		Test.Assert(blink.Stops.Count == 3); // 0%, 100%, 50%
	}
}
