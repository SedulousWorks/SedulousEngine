using System;
using Sedulous.I18N;

namespace Sedulous.I18N.Tests;

/// The resolver: the fallback chain, the last table winning, misses, plural forms by the
/// language the text came from, positional formatting, direction, pseudolocalization and
/// change callbacks.
class LocalizationTests
{
	/// English (the fallback) and Portuguese, with a Brazilian override for one key.
	private static void Base(StringTable t)
	{
		Test.Assert(t.AddLocale("en"));
		Test.Assert(t.AddLocale("pt"));
		Test.Assert(t.SetPluralRule("en", "one: n = 1"));
		Test.Assert(t.Set("menu.play", "en", "Play"));
		Test.Assert(t.Set("menu.play", "pt", "Jogar"));
		Test.Assert(t.Set("menu.quit", "en", "Quit"));
		Test.Assert(t.Set("menu.options", "pt-BR", "Opções"));
		Test.Assert(t.Set("menu.options", "en", "Options"));
		Test.Assert(t.SetPlural("files.count", "en", .One, "{0} file"));
		Test.Assert(t.SetPlural("files.count", "en", .Other, "{0} files"));
	}

	/// Each hop of the chain: the language, its parent, the fallback, the key.
	[Test]
	public static void EachHopOfTheChain()
	{
		let t = scope StringTable();
		Base(t);
		let loc = scope Localization();
		loc.AddTable(t);
		loc.SetLanguage("pt-BR");
		Test.Assert(loc.Text("menu.options") == "Opções", "the language itself");
		Test.Assert(loc.Text("menu.play") == "Jogar", "its parent");
		Test.Assert(loc.Text("menu.quit") == "Quit", "the fallback");
		Test.Assert(loc.Text("menu.none") == "menu.none", "a miss: the key itself");
		Test.Assert(loc.Has("menu.quit"));
		Test.Assert(!loc.Has("menu.none"));
		loc.SetFallbackLanguage("en-GB"); // the fallback's parent
		Test.Assert(loc.Text("menu.quit") == "Quit");
	}

	/// A miss is kept once, with the language it was asked in.
	[Test]
	public static void AMissIsKeptOnce()
	{
		let t = scope StringTable();
		Base(t);
		let loc = scope Localization();
		loc.AddTable(t);
		loc.SetLanguage("pt");
		loc.Text("menu.none");
		loc.Text("menu.none");
		loc.Text("menu.other");
		Test.Assert(loc.MissingKeys.Count == 2);
		Test.Assert(loc.MissingKeys[0].Key == "menu.none");
		Test.Assert(loc.MissingKeys[0].Language == "pt");
		loc.ClearMissingKeys();
		Test.Assert(loc.MissingKeys.IsEmpty);
	}

	/// The last table wins, and removing it uncovers the one below.
	[Test]
	public static void TheLastTableWins()
	{
		let baseTable = scope StringTable();
		Base(baseTable);
		let patch = scope StringTable();
		Test.Assert(patch.Set("menu.play", "en", "Start"));
		let loc = scope Localization();
		loc.AddTable(baseTable);
		loc.AddTable(patch);
		Test.Assert(loc.Text("menu.play") == "Start");
		loc.RemoveTable(patch);
		Test.Assert(loc.Text("menu.play") == "Play");
	}

	/// A plural form by the rule of the language whose text was found.
	[Test]
	public static void APluralFormByTheRuleOfTheLanguageItCameFrom()
	{
		let t = scope StringTable();
		Base(t);
		let loc = scope Localization();
		loc.AddTable(t);
		Test.Assert(loc.Plural("files.count", 1) == "{0} file");
		Test.Assert(loc.Plural("files.count", 2) == "{0} files");

		// Portuguese has no text for it: English's text, by English's rule.
		loc.SetLanguage("pt");
		Test.Assert(loc.Plural("files.count", 1) == "{0} file");

		// A locale with no rule counts all as other.
		Test.Assert(t.SetPlural("files.count", "pt", .One, "{0} arquivo"));
		Test.Assert(t.SetPlural("files.count", "pt", .Other, "{0} arquivos"));
		Test.Assert(loc.PluralCategoryOf("pt", 1) == .Other);
		Test.Assert(loc.Plural("files.count", 1) == "{0} arquivos");

		// Another table gives Portuguese its rule; the last such wins.
		let rules = scope StringTable();
		Test.Assert(rules.AddLocale("pt"));
		Test.Assert(rules.SetPluralRule("pt", "one: n = 1"));
		loc.AddTable(rules);
		Test.Assert(loc.Plural("files.count", 1) == "{0} arquivo");
		Test.Assert(loc.Text("files.count") == "{0} arquivos", "Text is the other form");
		Test.Assert(loc.Plural("menu.play", 3) == "Jogar", "a plain key: its text");
	}

	/// Positional formatting, reordered, escaped, and a missing argument shown.
	[Test]
	public static void PositionalFormatting()
	{
		let t = scope StringTable();
		Test.Assert(t.Set("greet", "en", "{1}, {0}!"));
		Test.Assert(t.Set("brace", "en", "{{{0}}} and {3}"));
		Test.Assert(t.SetPluralRule("en", "one: n = 1"));
		Test.Assert(t.SetPlural("lives", "en", .One, "{0} life left"));
		Test.Assert(t.SetPlural("lives", "en", .Other, "{0} lives left"));
		let loc = scope Localization();
		loc.AddTable(t);

		let text = scope String();
		loc.Format("greet", text, "Ana", "Hello");
		Test.Assert(text == "Hello, Ana!");
		loc.Format("brace", text..Clear(), (int32)7);
		Test.Assert(text == "{7} and {3}");
		loc.FormatPlural("lives", 3, text..Clear(), (int64)3);
		Test.Assert(text == "3 lives left");
		loc.Format("none.{0}", text..Clear(), true, 1.5, "x");
		Test.Assert(text == "none.true", "a missing key formats the key");
		// Beef spells a bool True; the text says it as the translations do.
		loc.Format("greet", text..Clear(), 1.5f, false);
		Test.Assert(text == "false, 1.5!", text);
	}

	/// The direction the tables say, through parents; left to right when none says.
	[Test]
	public static void TheDirectionTheTablesSay()
	{
		let t = scope StringTable();
		Test.Assert(t.AddLocale("ar"));
		t.SetDirection("ar", .RightToLeft);
		let loc = scope Localization();
		loc.AddTable(t);
		Test.Assert(!loc.IsRightToLeft());
		loc.SetLanguage("ar-EG");
		Test.Assert(loc.IsRightToLeft());
		Test.Assert(!loc.IsRightToLeft("fr"));

		let over = scope StringTable();
		Test.Assert(over.AddLocale("ar"));
		over.SetDirection("ar", .LeftToRight); // the last table wins
		loc.AddTable(over);
		Test.Assert(!loc.IsRightToLeft());
	}

	/// Pseudolocalization transforms text, leaving placeholders and named markup.
	[Test]
	public static void PseudolocalizationTransformsText()
	{
		let t = scope StringTable();
		Test.Assert(t.Set("msg", "en", "Hi {0} [b]x[/b]"));
		let loc = scope Localization();
		loc.AddTable(t);

		let pseudo = scope PseudoOptions();
		pseudo.Enabled = true;
		pseudo.Lengthen = 0.0f;
		pseudo.Untouched.Add(new .("[", "]"));
		loc.SetPseudolocalization(pseudo);
		// x has no look-alike in Latin-1 or Latin Extended-A, so it stays.
		Test.Assert(loc.Text("msg") == "[Ĥî {0} [b]x[/b]]", scope $"{loc.Text("msg")}");

		pseudo.Lengthen = 0.5f;
		pseudo.Brackets = false;
		ClearAndDeleteItems!(pseudo.Untouched);
		pseudo.ShowKeys = true;
		loc.SetPseudolocalization(pseudo);
		Test.Assert(t.Set("two", "en", "ab"));
		Test.Assert(loc.Text("two") == "two: áb~", "half again as long");
		Test.Assert(loc.Text("gone") == "gone: ĝöñé~~", "a miss transformed too");

		// A mirrored direction: wrapped in a right to left embedding (U+202B) and its pop
		// (U+202C).
		pseudo.ShowKeys = false;
		pseudo.Lengthen = 0.0f;
		pseudo.RightToLeft = true;
		loc.SetPseudolocalization(pseudo);
		let mirrored = loc.Text("two");
		Test.Assert(mirrored == "\u{202B}áb\u{202C}");
		Test.Assert(((uint8)mirrored[0] == 0xE2) && ((uint8)mirrored[1] == 0x80) && ((uint8)mirrored[2] == 0xAB));
	}

	/// Changes call back; a removed token does not.
	[Test]
	public static void ChangesCallBack()
	{
		let t = scope StringTable();
		let loc = scope Localization();
		int calls = 0;
		let token = loc.OnChanged(new [&calls]() => { calls++; });
		loc.SetLanguage("de");
		loc.AddTable(t);
		loc.RemoveTable(t);
		loc.SetPseudolocalization(scope PseudoOptions());
		Test.Assert(calls == 4);
		loc.RemoveOnChanged(token);
		loc.SetLanguage("fr");
		Test.Assert(calls == 4);
	}
}
