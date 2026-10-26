using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.VG;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;
using Sedulous.I18N;
using Sedulous.GUI;
using Sedulous.GUI.Testing;

namespace Sedulous.GUI.Fuzz.Tests;

/// A deterministic source of numbers (xorshift64*), so a failing mutation is found again from its seed.
/// Raptor's `Random`, named for the fuzzer: Sedulous.Core has a Random (PCG32) of its own.
struct FuzzRandom
{
	public uint64 State;

	public this(uint64 seed)
	{
		State = (seed != 0) ? seed : 0x9e3779b97f4a7c15UL;
	}

	public uint64 Next() mut
	{
		State ^= State >> 12;
		State ^= State << 25;
		State ^= State >> 27;
		return State &* 0x2545f4914f6cdd1dUL;
	}

	public uint32 Below(uint32 bound) mut => (bound == 0) ? 0 : (uint32)(Next() % (uint64)bound);

	public float Unit() mut => (float)(Next() >> 40) / (float)((uint32)1 << 24);
}

/// The fuzz targets (E10 of Specs/gui-lab-evolution-2.md) and what feeds them: seeds from the
/// sandbox's own pages and string table, and a deterministic mutator. A target takes any bytes and
/// must neither crash nor hang; what it builds is thrown away.
static class FuzzTargets
{
	/// Which target a run of bytes goes to: what Raptor's libFuzzer entry chose by GUI_FUZZ_TARGET.
	public enum Target
	{
		Css,
		Markup,
		Keymap,
		StringTable,
		Input,
	}

	public static String[?] cCssTokens = .(
		"{", "}", ";", ":", "(", ")", ",", "\"", "'", "/*", "*/", "@media ", "@keyframes x ", "@import ",
		"var(--a)", "var(--a, var(--b))", "calc(1px + 50%)", "::thumb", ":hover", ":not(", ">", "+", "~", "*",
		"#id", ".cls", "[attr=v]", "!important", "url(", "rgba(1,2,3", "#ff00ff", "1e999", "-0.5px", "100%",
		"transition: all 1s;", "animation: x 1s infinite;", "--a: ", "\\", "\n", "\t", "\xF0\x9F", "\xC3");
	/// The element tags are the GUI's own (tags are case sensitive), and one lowercase `<button`
	/// that names no element, as Raptor's list keeps it.
	public static String[?] cMarkupTokens = .(
		"<", ">", "</", "/>", "=\"", "\"", "'", "&amp;", "&#x1F600;", "&bogus;", "<!--", "-->", "<![CDATA[",
		"]]>", "<?xml ?>", "<Button", "<Panel>", "</Panel>", "<Label text=\"", "<ScrollView>", "</ScrollView>",
		"<TextField", "<button", "style=\"", "class=\"", "id=\"",
		"{{name}}", "{{", "}}", "data-x=\"", "-count=\"", "-args=\"", "\xEF\xBB\xBF", "\0", "\xE2\x80\xAE");
	/// Raptor's tokens, then the keystroke syntax the parser reads ("ctrl-shift-s", "pad-south"):
	/// Raptor's are written "Ctrl+S", which parses as no keystroke.
	public static String[?] cKeymapTokens = .(
		"Ctrl+", "Shift+", "Alt+", "Super+", "+", " ", "K", "F12", "Escape", "Pad.South", "Pad.", "&&", "||", "!",
		"(", ")", "editing", "menu && !popup", "\xC3\xA9", "Ctrl+K Ctrl+", "++", "  ",
		"ctrl-", "shift-", "alt-", "super-", "-", "pad-", "pad-south", "f12", "escape", "ctrl-k ctrl-");
	public static String[?] cXmlTokens = .(
		"<", ">", "</", "/>", "=\"", "\"", "<Entry", "<Locale", "</Locales>", "&lt;", "&#0;", "&#xFFFFFF;",
		"<?xml version=\"1.0\"?>", "<!DOCTYPE x>", "type=\"", "{0}", "{1, plural, one {a} other {b}}", "\xC3");

	/// Every registered element type; what each target's loader makes from.
	private static ElementSet sElements = ElementSet.All() ~ delete _;

	/// The tree the CSS target styles: one of each kind of element.
	public const String cCssTree = "<Panel><Button text=\"b\"/><Label class=\"note\" text=\"l\"/><TextField/><Slider/>" +
		"<CheckBox/><ListBox/><ScrollView><Label text=\"in\"/></ScrollView></Panel>";

	/// Mutates `text` a few times: a byte flipped, a span cut or doubled, a piece of syntax or a
	/// stray byte put in, the end cut off. `tokens` is the target's syntax.
	public static void Mutate(String text, ref FuzzRandom random, Span<String> tokens)
	{
		let piece = scope String();
		let edits = 1 + random.Below(6);
		for (uint32 e = 0; e < edits; e++)
		{
			let size = text.Length;
			let at = (size == 0) ? 0 : (int)random.Below((uint32)size);
			switch (random.Below(7))
			{
			case 0: // flip a byte
				if (size > 0)
					text[at] = (char8)((uint8)text[at] ^ (uint8)((uint32)1 << random.Below(8)));
			case 1: // cut a span
				if (size > 0)
					text.Remove(at, 1 + (int)random.Below((uint32)Math.Min(size - at, 64)));
			case 2: // double a span
				if (size > 0)
				{
					piece.Set(StringView(text, at, 1 + (int)random.Below((uint32)Math.Min(size - at, 64))));
					text.Insert(at, piece);
				}
			case 3: // a piece of syntax
				text.Insert(at, tokens[random.Below((uint32)tokens.Length)]);
			case 4: // a byte of anything, a broken UTF-8 lead among them
				text.Insert(at, (char8)random.Below(256));
			case 5: // the end cut off
				text.RemoveToEnd(at);
			default: // a run nested deep
				// The count first, then the token: C++ leaves the order of a constructor's
				// arguments open, so this is the order as written.
				let count = 1 + (int)random.Below(200);
				let c = tokens[random.Below((uint32)tokens.Length)][0];
				text.Insert(at, c, count);
			}
		}
	}

	/// The file's bytes, appended to `outBytes`; false (nothing appended) when it does not read.
	public static bool ReadBytes(StringView path, String outBytes)
	{
		let bytes = scope List<uint8>();
		if (ReadFile(path, bytes) case .Err)
			return false;
		outBytes.Append(StringView((char8*)bytes.Ptr, bytes.Count));
		return true;
	}

	/// Each file directly in `directory` with this extension (empty: every file), read into
	/// `outSeeds` in name order. Raptor took them in the directory's order, which a platform
	/// leaves open; by name, a mutation's seed index names the same input everywhere.
	private static void ReadDirectory(StringView directory, StringView @extension, List<String> outSeeds)
	{
		let wanted = @extension; // the lambda captures this alias, not the escaped name
		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		ListDirectory(directory, scope [&] (name, isDirectory) =>
			{
				if (isDirectory)
					return;
				if (!wanted.IsEmpty && (PathExtension(name, .. scope String()) != wanted))
					return;
				names.Add(new String(name));
			});
		names.Sort(scope (lhs, rhs) => String.Compare(lhs, rhs, false));
		for (let name in names)
		{
			let seed = new String();
			ReadBytes(PathJoin(directory, name, .. scope String()), seed);
			outSeeds.Add(seed);
		}
	}

	/// The sandbox's pages with this extension (`.css`, `.xml`), its main sheet among them: real
	/// input, every feature the GUI has written down once. The caller deletes what is added.
	public static void SandboxSeeds(StringView @extension, List<String> outSeeds)
	{
		let root = FindDataRoot(.. scope String());
		let @base = DataPath(root, "Assets/ui/sandbox", .. scope String());
		ReadDirectory(@base, @extension, outSeeds);
		ReadDirectory(PathJoin(@base, "pages", .. scope String()), @extension, outSeeds);
	}

	/// Inputs a fuzzer found once, kept to run every time: Data/Tests/GUI/Fuzz/<kind>/*. The caller
	/// deletes what is added.
	public static void FoundSeeds(StringView kind, List<String> outSeeds)
	{
		let root = FindDataRoot(.. scope String());
		let relative = scope String()..AppendF("Tests/GUI/Fuzz/{}", kind);
		ReadDirectory(DataPath(root, relative, .. scope String()), default, outSeeds);
	}

	/// A root of a GUI of its own, `width` by `height`, held by the caller: it releases it, and the
	/// GUI goes with it.
	public static SceneRoot NewRoot(float width, float height)
	{
		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		root.Size = .(width, height);
		return root;
	}

	// === The targets ===

	/// A sheet parsed, then applied to a small tree of every element kind.
	public static void FuzzCss(StringView text)
	{
		RegisterGuiElements();
		let root = NewRoot(320.0f, 240.0f);
		defer root.ReleaseRef();
		let loader = scope MarkupLoader(sElements);
		if (let tree = loader.LoadFromString(cCssTree))
		{
			root.AddChild(tree);
			tree.ReleaseRef();
		}
		let sheet = scope StyleSheet();
		CSSParser.Parse(text, sheet);
		let styles = scope StyleManager(sheet);
		styles.ApplyTree(root);
		root.UpdateLayout();
	}

	/// Markup loaded into a root, styled, laid out and drawn.
	/// Whether `text` loads as a tree at all: a seed that does not reaches no further than the
	/// loader, and the targets past it run on an empty root.
	public static bool Loads(StringView text)
	{
		RegisterGuiElements();
		let loader = scope MarkupLoader(sElements);
		let tree = loader.LoadFromString(text);
		if (tree == null)
			return false;
		tree.ReleaseRef();
		return true;
	}

	public static void FuzzMarkup(StringView text)
	{
		RegisterGuiElements();
		let root = NewRoot(320.0f, 240.0f);
		defer root.ReleaseRef();
		let loader = scope MarkupLoader(sElements);
		let tree = loader.LoadFromString(text);
		if (tree == null)
			return;
		root.AddChild(tree);
		tree.ReleaseRef();
		let sheet = scope StyleSheet();
		CSSParser.Parse("* { padding: 2; } button { background-color: #333; }", sheet);
		let styles = scope StyleManager(sheet);
		styles.ApplyTree(root);
		root.UpdateLayout();
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		root.Draw(dc);
	}

	/// Lines of `keys|command|context` bound into a keymap, each line's keys parsed as a keystroke
	/// too. The count of lines that bound.
	public static int FuzzKeymap(StringView text)
	{
		let keymap = scope Keymap();
		int bound = 0;
		int start = 0;
		while (start <= text.Length)
		{
			var end = text.IndexOf('\n', start);
			if (end < 0)
				end = text.Length;
			let line = StringView(text, start, end - start);
			let a = line.IndexOf('|');
			let b = (a < 0) ? -1 : line.IndexOf('|', a + 1);
			let keys = (a < 0) ? line : StringView(line, 0, a);
			let command = (a < 0) ? StringView("c") : ((b < 0) ? StringView(line, a + 1) : StringView(line, a + 1, b - a - 1));
			let context = (b < 0) ? StringView() : StringView(line, b + 1);
			if (keymap.Bind(keys, command, context))
				bound++;
			ParseKeystroke(keys);
			start = end + 1;
		}
		return bound;
	}

	/// A string table read from XML, then asked for its texts.
	public static void FuzzStringTable(StringView text)
	{
		let document = scope XmlDocument();
		if (document.Parse(text) != .Ok)
			return;
		let reader = scope XmlSerializer(document);
		let table = scope StringTable();
		table.Serialize(reader);
		let localization = scope Localization(); // after the table: it goes first, the table borrowed
		localization.AddTable(table);
		localization.Text("lang.changed");
		localization.SetLanguage("ar");
		localization.Text("gui.ok");
	}

	/// The bytes of an input stream, read one at a time; past the end, zero.
	private struct InputBytes
	{
		public StringView Bytes;
		public int At = 0;

		public this(StringView bytes)
		{
			Bytes = bytes;
		}

		public bool AtEnd => At >= Bytes.Length;

		public uint32 Next() mut => (At < Bytes.Length) ? (uint32)(uint8)Bytes[At++] : 0;

		public Float2 Point() mut
		{
			let x = (float)Next() * 2.6f - 10.0f;
			let y = (float)Next() * 2.0f - 10.0f;
			return .(x, y);
		}
	}

	/// A sandbox page under a stream of input the bytes decide: pointer, wheel, keys, text and
	/// composition (broken UTF-8 included), touch, pad, file drops, and frames between them.
	public static void FuzzInput(StringView markup, StringView sheetText, StringView bytes)
	{
		RegisterGuiElements();
		let root = NewRoot(640.0f, 480.0f);
		defer root.ReleaseRef();
		let loader = scope MarkupLoader(sElements);
		if (let tree = loader.LoadFromString(markup))
		{
			root.AddChild(tree);
			tree.ReleaseRef();
		}
		let sheet = scope StyleSheet();
		CSSParser.Parse(sheetText, sheet);
		let styles = scope StyleManager(sheet);
		let tester = scope Tester(root, styles);
		let input = root.EventDispatcher;
		var stream = InputBytes(bytes);
		let text = scope String();
		while (!stream.AtEnd)
		{
			switch (stream.Next() % 14)
			{
			case 0: input.InjectMouseMove(stream.Point(), stream.Next() & 15);
			case 1: input.InjectMouseDown(stream.Point(), (MouseButton)(stream.Next() % 5), stream.Next() & 15);
			case 2: input.InjectMouseUp(stream.Point(), (MouseButton)(stream.Next() % 5), stream.Next() & 15);
			case 3:
				let at = stream.Point();
				let dx = (float)stream.Next() - 128.0f;
				let dy = (float)stream.Next() - 128.0f;
				input.InjectMouseWheel(at, .(dx, dy));
			case 4: input.InjectKeyDown(stream.Next() % 80, stream.Next() & 15); // unknown codes among them
			case 5: input.InjectKeyUp(stream.Next() % 80, stream.Next() & 15);
			case 6:
				text.Clear();
				for (uint32 n = stream.Next() % 6; n > 0; n--)
					text.Append((char8)stream.Next());
				input.InjectText(text);
			case 7:
				text.Clear();
				for (uint32 n = stream.Next() % 6; n > 0; n--)
					text.Append((char8)stream.Next());
				input.InjectComposition(text, (int32)(stream.Next() % 8) - 2);
			case 8: input.InjectTouchDown(stream.Next() % 3, stream.Point());
			case 9: input.InjectTouchMove(stream.Next() % 3, stream.Point());
			case 10: input.InjectTouchUp(stream.Next() % 3, stream.Point());
			case 11: input.InjectPadButton((PadButton)(stream.Next() % 8));
			case 12:
				StringView[1] paths = .("/tmp/a file.png");
				input.InjectFileDrop(stream.Point(), Span<StringView>(&paths[0], 1));
			default:
				let seconds = (double)((float)stream.Next() / 255.0f);
				tester.Advance(TimeSpan((int64)(seconds * (double)TimeSpan.TicksPerSecond)));
			}
		}
		tester.Frame();
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		root.Draw(dc);
	}

	/// `bytes` through `target`: what Raptor's libFuzzer entry (LLVMFuzzerTestOneInput) did with
	/// one input. The input target puts it on one of `pages` (with one of `sheets`), chosen by its
	/// length; with no pages it does nothing.
	public static void FuzzOne(Target target, StringView bytes, Span<String> pages, Span<String> sheets)
	{
		switch (target)
		{
		case .Css: FuzzCss(bytes);
		case .Markup: FuzzMarkup(bytes);
		case .Keymap: FuzzKeymap(bytes);
		case .StringTable: FuzzStringTable(bytes);
		case .Input:
			if (!pages.IsEmpty)
				FuzzInput(pages[bytes.Length % pages.Length], sheets.IsEmpty ? "" : sheets[bytes.Length % sheets.Length], bytes);
		}
	}
}
