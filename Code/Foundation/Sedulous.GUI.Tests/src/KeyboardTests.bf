using System;
using System.Collections;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The keyboard: a captured key and its cancel, access keys in a label's text, and type-ahead's
/// matching across cases and scripts.
class KeyboardTests
{
	[Test]
	public static void EscapeCancelsACaptureUnlessTheCallerTakesIt()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let taken = scope List<Keystroke>();
		int cancels = 0;
		d.CaptureNextKey(new [&] (stroke) => { taken.Add(stroke); }, new [&] () => { cancels++; });
		d.InjectKeyDown((uint32)KeyCode.Escape, 0);
		Test.Assert(cancels == 1);
		Test.Assert(taken.IsEmpty);
		Test.Assert(!d.IsCapturingKey);
		d.CaptureNextKey(new [&] (stroke) => { taken.Add(stroke); }, new [&] () => { cancels++; }, true);
		d.InjectKeyDown((uint32)KeyCode.Escape, 0);
		Test.Assert(taken.Count == 1);
		Test.Assert(taken[0].Code == (uint32)KeyCode.Escape);
		Test.Assert(cancels == 1);
		// A second capture replaces a waiting one, which is cancelled.
		d.CaptureNextKey(new [&] (stroke) => { taken.Add(stroke); }, new [&] () => { cancels++; });
		d.CaptureNextKey(new [&] (stroke) => { taken.Add(stroke); });
		Test.Assert(cancels == 2);
	}

	[Test]
	public static void AnAmpersandMarksAnAccessKeyAndADoubledOneIsAnAmpersand()
	{
		let m = scope Mnemonic();
		ParseMnemonic("&File", m);
		Test.Assert(m.Shown == "File");
		Test.Assert(m.Key == 'f');
		Test.Assert(m.Start == 0);
		Test.Assert(m.End == 1);
		ParseMnemonic("E&xit", m);
		Test.Assert(m.Shown == "Exit");
		Test.Assert(m.Key == 'x');
		Test.Assert(m.Start == 1);
		ParseMnemonic("Save && Quit", m);
		Test.Assert(m.Shown == "Save & Quit");
		Test.Assert(m.Key == (char32)0);
	}

	[Test]
	public static void TypeAheadMatchesLettersInEitherCaseInLatinGreekAndCyrillic()
	{
		Test.Assert(StartsWithIgnoringCase("Banana", "ba"));
		Test.Assert(StartsWithIgnoringCase("Éclair", "é")); // É, é
		Test.Assert(StartsWithIgnoringCase("Łódź", "ł")); // Ł, ł
		Test.Assert(StartsWithIgnoringCase("Δέλτα", "δ")); // Δ, δ
		Test.Assert(StartsWithIgnoringCase("Груша", "гр")); // Гр, гр
		Test.Assert(StartsWithIgnoringCase("Ёлка", "ё")); // Ё, ё
		Test.Assert(!StartsWithIgnoringCase("Apple", "b"));
		Test.Assert(!StartsWithIgnoringCase("A", "ab"));
	}
}
