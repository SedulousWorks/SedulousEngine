using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VFS;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;
using Sedulous.I18N;
using Sedulous.GUI;

namespace Sedulous.GUI.Fuzz.Tests;

/// The fuzz targets as tests (E10 of Specs/gui-lab-evolution-2.md): each target takes every seed,
/// then a seeded run of mutations of each, and must neither crash nor hang. A crash a long fuzzer
/// run finds goes in as a seed (Data/Tests/GUI/Fuzz/<kind>/), so every run takes it from then on.
/// The count of mutations per seed is GUI_FUZZ_RUNS (default 40), so a long local run is one
/// variable away.
class FuzzTests
{
	private static int Runs()
	{
		let value = scope String();
		if (Environment.GetEnvironmentVariable("GUI_FUZZ_RUNS", value) case .Ok)
		{
			if (int.Parse(value) case .Ok(let runs))
				return Math.Max(1, runs);
			return 1; // a value that is no number: at least one run, as Raptor's strtol read it
		}
		return 40;
	}

	// Every seed, then Runs() mutations of each, through `target`; the seed of a mutation is its
	// index, so a failure names what to replay.
	private static void Run(List<String> seeds, Span<String> tokens, delegate void(StringView text) target)
	{
		Test.Assert(!seeds.IsEmpty);
		for (let seed in seeds)
			target(seed);
		let runs = Runs();
		let text = scope String();
		for (int s = 0; s < seeds.Count; s++)
		{
			for (int r = 0; r < runs; r++)
			{
				var random = FuzzRandom(0x5eed0000UL + (uint64)s * 100003UL + (uint64)r);
				text.Set(seeds[s]);
				FuzzTargets.Mutate(text, ref random, tokens);
				target(text);
			}
		}
	}

	[Test]
	public static void TheCssParserAndCascadeTakeAnySheet()
	{
		let seeds = scope List<String>();
		defer { ClearAndDeleteItems!(seeds); }
		FuzzTargets.SandboxSeeds(".css", seeds);
		FuzzTargets.FoundSeeds("css", seeds);
		seeds.Add(new String(""));
		seeds.Add(new String("@media (min-width: 10px) { button { color: red } } @keyframes k { 0% { opacity: 0 } }"));
		seeds.Add(new String("a { b: c; } } } { { ; ;; : : var(--x, var(--y, var(--z)))"));
		Run(seeds, Span<String>(&FuzzTargets.cCssTokens[0], FuzzTargets.cCssTokens.Count), scope (text) => FuzzTargets.FuzzCss(text));
	}

	[Test]
	public static void TheMarkupLoaderTakesAnyMarkup()
	{
		let seeds = scope List<String>();
		defer { ClearAndDeleteItems!(seeds); }
		FuzzTargets.SandboxSeeds(".xml", seeds);
		FuzzTargets.FoundSeeds("markup", seeds);
		seeds.Add(new String(""));
		seeds.Add(new String("<Panel><Panel><Panel><Button text=\"{{a.b}}\" style=\"color: red\"/></Panel></Panel></Panel>"));
		seeds.Add(new String("<unknown attr=\"\"><Label text=\"&#x110000;\"/></unknown>"));
		Run(seeds, Span<String>(&FuzzTargets.cMarkupTokens[0], FuzzTargets.cMarkupTokens.Count), scope (text) => FuzzTargets.FuzzMarkup(text));
	}

	[Test]
	public static void TheKeymapTakesAnyBindings()
	{
		let seeds = scope List<String>();
		defer { ClearAndDeleteItems!(seeds); }
		FuzzTargets.FoundSeeds("keymap", seeds);
		seeds.Add(new String("Ctrl+S|file.save|\nCtrl+K Ctrl+C|edit.comment|editing && !readonly\nPad.South|ui.activate|menu"));
		seeds.Add(new String("|||\n+\nCtrl+\n(((((\n"));
		seeds.Add(new String(cBindingSeed));
		Run(seeds, Span<String>(&FuzzTargets.cKeymapTokens[0], FuzzTargets.cKeymapTokens.Count), scope (text) => { FuzzTargets.FuzzKeymap(text); });
	}

	[Test]
	public static void TheStringTableReaderTakesAnyXml()
	{
		let seeds = scope List<String>();
		defer { ClearAndDeleteItems!(seeds); }
		let sandbox = new String();
		seeds.Add(sandbox);
		FuzzTargets.ReadBytes(SandboxStringsPath(.. scope String()), sandbox);
		Test.Assert(!sandbox.IsEmpty);
		FuzzTargets.FoundSeeds("strings", seeds); // cells-not-one-a-locale: an entry short of the locales' cells
		seeds.Add(new String("<?xml version=\"1.0\"?><a><b/></a>"));
		Run(seeds, Span<String>(&FuzzTargets.cXmlTokens[0], FuzzTargets.cXmlTokens.Count), scope (text) => FuzzTargets.FuzzStringTable(text));
	}

	[Test]
	public static void APageTakesAnyStreamOfInput()
	{
		// Each sandbox page with its own sheet (both in name order, so a page meets its own),
		// under random input streams.
		let pages = scope List<String>();
		defer { ClearAndDeleteItems!(pages); }
		let sheets = scope List<String>();
		defer { ClearAndDeleteItems!(sheets); }
		FuzzTargets.SandboxSeeds(".xml", pages);
		FuzzTargets.SandboxSeeds(".css", sheets);
		Test.Assert(!pages.IsEmpty);
		let runs = Math.Max(1, Runs() / 8);
		let stream = scope String();
		for (int p = 0; p < pages.Count; p++)
		{
			let sheet = sheets.IsEmpty ? "" : sheets[p % sheets.Count];
			for (int r = 0; r < runs; r++)
			{
				var random = FuzzRandom(0x1a7e0000UL + (uint64)p * 7919UL + (uint64)r);
				stream.Clear();
				for (uint32 n = 0; n < 2000; n++)
					stream.Append((char8)random.Below(256));
				FuzzTargets.FuzzInput(pages[p], sheet, stream);
			}
		}
	}

	// === What the runs rest on ===

	/// Bindings in the syntax the keymap reads: Raptor's seeds write "Ctrl+S", which binds nothing,
	/// so its mutations never reached a binding.
	private const String cBindingSeed = "ctrl-s|file.save|\nctrl-k ctrl-c|edit.comment|editing && !readonly\npad-south|ui.activate|menu";

	private static void SandboxStringsPath(String outPath)
	{
		let root = FindDataRoot(.. scope String());
		DataPath(root, "Samples/UI/sandbox/i18n/sandbox.strings.xml", outPath);
	}

	/// A mutation is found again from its seed: the same seed makes the same numbers and the same
	/// mutation; a zero seed does not stick at zero (xorshift would).
	[Test]
	public static void AMutationIsFoundAgainFromItsSeed()
	{
		// Raptor's xorshift64* exactly, so a seed names the same mutation in both engines.
		var known = FuzzRandom(0x5eed0000);
		Test.Assert(known.Next() == 0xa590073e3c770093UL);
		Test.Assert(known.Next() == 0x81d6b2d7da67749cUL);
		Test.Assert(known.Next() == 0x39985f217b70e9c0UL);
		var zero = FuzzRandom(0);
		var fallback = FuzzRandom(0x9e3779b97f4a7c15UL);
		Test.Assert(zero.Next() == fallback.Next());
		Test.Assert(zero.Next() != 0);
		Test.Assert(zero.Below(0) == 0);
		for (int i = 0; i < 100; i++)
		{
			let unit = zero.Unit();
			Test.Assert((unit >= 0.0f) && (unit < 1.0f));
			Test.Assert(zero.Below(7) < 7);
		}

		let tokens = Span<String>(&FuzzTargets.cMarkupTokens[0], FuzzTargets.cMarkupTokens.Count);
		let first = scope String();
		let second = scope String();
		var differs = false;
		for (uint64 seed = 1; seed <= 20; seed++)
		{
			first.Set("<Panel><Button text=\"a\"/></Panel>");
			second.Set(first);
			var a = FuzzRandom(seed);
			var b = FuzzRandom(seed);
			FuzzTargets.Mutate(first, ref a, tokens);
			FuzzTargets.Mutate(second, ref b, tokens);
			Test.Assert(first == second);
			Test.Assert(a.State == b.State);
			if (first != "<Panel><Button text=\"a\"/></Panel>")
				differs = true;
		}
		Test.Assert(differs); // the mutator changes what it is given
	}

	/// The CSS target's tree loads, one of each kind of element: a tree that did not would leave
	/// the sheet styling an empty root (as Raptor's lower case tags did).
	[Test]
	public static void TheCssTargetsTreeHasOneOfEachKindOfElement()
	{
		RegisterGuiElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		let tree = loader.LoadFromString(FuzzTargets.cCssTree);
		Test.Assert(tree != null);
		if (tree == null)
			return;
		defer tree.ReleaseRef();
		Test.Assert(tree is Panel);
		Test.Assert(tree.ChildCount == 7);
		Test.Assert(tree.GetChildAt(0) is Button);
		Test.Assert(tree.GetChildAt(1) is Sedulous.GUI.Label);
		Test.Assert(tree.GetChildAt(2) is TextField);
		Test.Assert(tree.GetChildAt(3) is Slider);
		Test.Assert(tree.GetChildAt(4) is CheckBox);
		Test.Assert(tree.GetChildAt(5) is ListBox);
		Test.Assert(tree.GetChildAt(6) is ScrollView);
	}

	/// The seeds reach past the parsers: the keymap seed binds each of its lines, the sandbox's
	/// string table reads whole (its texts in both languages), and the fuzzer's find reads as a
	/// failed payload that still answers.
	[Test]
	public static void TheSeedsReachPastTheParsers()
	{
		Test.Assert(FuzzTargets.FuzzKeymap(cBindingSeed) == 3);

		let sandbox = scope String();
		Test.Assert(FuzzTargets.ReadBytes(SandboxStringsPath(.. scope String()), sandbox));
		{
			let document = scope XmlDocument();
			Test.Assert(document.Parse(sandbox) == .Ok);
			let reader = scope XmlSerializer(document);
			let table = scope StringTable();
			table.Serialize(reader);
			Test.Assert(reader.IsPayloadOk);
			let localization = scope Localization();
			localization.AddTable(table);
			Test.Assert(localization.Text("lang.changed") == "Language: English");
			localization.SetLanguage("ar");
			Test.Assert(localization.Text("gui.ok") == "موافق");
		}

		let found = scope List<String>();
		defer { ClearAndDeleteItems!(found); }
		FuzzTargets.FoundSeeds("strings", found);
		Test.Assert(found.Count == 1);
		for (let seed in found)
		{
			let document = scope XmlDocument();
			Test.Assert(document.Parse(seed) == .Ok);
			let reader = scope XmlSerializer(document);
			let table = scope StringTable();
			table.Serialize(reader);
			Test.Assert(!reader.IsPayloadOk); // gui.ok's cells are one, the locales two
			let localization = scope Localization();
			localization.AddTable(table);
			localization.SetLanguage("ar");
			localization.Text("gui.ok");
		}
	}

	/// Every target takes the others' input: each target's own seeds (its CSS, markup, bindings
	/// and XML) through every target, the input target putting them on a sandbox page as a stream.
	[Test]
	public static void EveryTargetTakesTheOthersInput()
	{
		let pages = scope List<String>();
		defer { ClearAndDeleteItems!(pages); }
		let sheets = scope List<String>();
		defer { ClearAndDeleteItems!(sheets); }
		FuzzTargets.SandboxSeeds(".xml", pages);
		FuzzTargets.SandboxSeeds(".css", sheets);
		Test.Assert(!pages.IsEmpty);
		String[?] inputs = .(
			"",
			"@media (min-width: 10px) { button { color: red } } @keyframes k { 0% { opacity: 0 } }",
			"<Panel><Panel><Panel><Button text=\"{{a.b}}\" style=\"color: red\"/></Panel></Panel></Panel>",
			"<unknown attr=\"\"><Label text=\"&#x110000;\"/></unknown>",
			cBindingSeed,
			"|||\n+\nCtrl+\n(((((\n",
			"<?xml version=\"1.0\"?><a><b/></a>",
			FuzzTargets.cCssTree);
		let pageSpan = Span<String>(pages.Ptr, pages.Count);
		let sheetSpan = Span<String>(sheets.Ptr, sheets.Count);
		for (let input in inputs)
		{
			for (int t = 0; t <= (int)FuzzTargets.Target.Input; t++)
				FuzzTargets.FuzzOne((FuzzTargets.Target)t, input, pageSpan, sheetSpan);
		}
	}

	/// Every sandbox page loads as a tree, so the markup and input runs reach the styles, the
	/// layout and the input past the loader rather than an empty root.
	[Test]
	public static void EverySandboxPageLoadsAsATree()
	{
		let pages = scope List<String>();
		defer { ClearAndDeleteItems!(pages); }
		FuzzTargets.SandboxSeeds(".xml", pages);
		Test.Assert(pages.Count >= 20);
		int loaded = 0;
		for (let page in pages)
		{
			if (FuzzTargets.Loads(page))
				loaded++;
		}
		Test.Assert(loaded == pages.Count, scope $"{loaded} of {pages.Count} pages load");
	}
}
