using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.VFS;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;
using Sedulous.GUI;

namespace Sedulous.GUI.Code.Tests;

/// A font of 6px advance per byte, 12px line height (ascent 10, descent 2), no file and no shaper:
/// its pieces lay out unshaped.
class SixFont : IFont
{
	public override void GetFamilyName(String outName) { outName.Append("six"); }
	public override Span<uint8> SourceData => default;
	public override FontMetrics Metrics => .(10.0f, -2.0f, 0.0f, 10.0f, 1.0f);
	public override float PixelHeight => 10.0f;

	public override GlyphInfo GetGlyphInfo(int32 codepoint)
	{
		var g = GlyphInfo();
		g.Codepoint = codepoint;
		g.AdvanceWidth = 6.0f;
		return g;
	}

	public override float GetKerning(int32 firstCodepoint, int32 secondCodepoint) => 0.0f;
	public override bool HasGlyph(int32 codepoint) => true;
	public override float MeasureString(StringView text) => (float)text.Length * 6.0f;
	public override float MeasureString(StringView text, List<GlyphPosition> outPositions) => (float)text.Length * 6.0f;
}

/// A clipboard in memory.
class MemoryClipboard : IClipboard
{
	public String Text = new .() ~ delete _;

	public bool HasText => Text.Length != 0;
	public void GetText(String outText) { outText.Append(Text); }
	public void SetText(StringView text) { Text.Set(text); }
}

/// What the code editor's tests share.
static class CodeFixtures
{
	public static CodePosition At(uint32 line, uint32 column) => .(line, column);

	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	public static bool Near(float a, float b, float epsilon = 1.2e-5f) =>
		Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));

	/// One of the shared definitions (Data/Editor/Code, the editor's and the sandbox's), read as they read it,
	/// into `out`.
	public static bool LoadSandboxLanguage(StringView id, CodeLanguage @out)
	{
		let root = FindDataRoot(.. scope String());
		let relative = scope String()..AppendF("Editor/Code/{}.xml", id);
		let path = DataPath(root, relative, .. scope String());
		let text = scope String();
		if (File.ReadAllText(path, text, true) case .Err)
			return false;
		let doc = scope XmlDocument();
		if (doc.Parse(text) != .Ok)
			return false;
		let reader = scope XmlSerializer(doc);
		@out.Serialize(reader);
		return reader.IsOk && !@out.Contexts.IsEmpty;
	}

	/// A press and its release at `at` (the root's space).
	public static void Click(EventDispatcher d, Float2 at, uint32 modifiers = 0)
	{
		d.InjectMouseDown(at, .Left, modifiers);
		d.InjectMouseUp(at, .Left, modifiers);
	}
}

/// An editor `height` tall and 400 across at the top-left of a root 800 by 600, in a GUI whose
/// keymap has the code editor's keys, focused, in the mock font (6px a byte, 12px a line); in the
/// sandbox's `language` when one is named. The font, the root and the editor go with it.
class CodeBed
{
	// Declared first, so it goes last: the editor borrows it.
	public CachedFont Font = new .(new SixFont(), null) ~ delete _;
	public CodeLanguage Language = new .() ~ delete _;
	public MemoryClipboard Clipboard = new .() ~ delete _;
	public SceneRoot Root ~ _.ReleaseRef();
	public CodeEditor Editor = new .() ~ _.ReleaseRef();
	private bool mOwnsClipboard = false;

	public this(StringView language, StringView text, float height = 240.0f, bool clipboard = false)
	{
		let context = new GUIContext();
		Root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		if (language.Length != 0)
		{
			Test.Assert(CodeFixtures.LoadSandboxLanguage(language, Language), "the sandbox's definition reads");
		}
		BindCodeEditorKeys(Root.Context.Keymap); // the host's, once for its GUI
		Root.Size = .(800.0f, 600.0f);
		Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		Editor.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(400.0f);
				s.Height = LayoutLength.Px(height);
			});
		Editor.Font = Font;
		Root.AddChild(Editor);
		if (clipboard)
		{
			D.Clipboard = Clipboard;
			mOwnsClipboard = true;
		}
		if (language.Length != 0)
			Editor.SetLanguage(Language);
		Editor.SetText(text);
		Frame();
		Editor.RequestFocus();
	}

	public ~this()
	{
		if (mOwnsClipboard)
			D.Clipboard = null;
	}

	public EventDispatcher D => Root.EventDispatcher;

	public void Frame(float seconds = 0.016f)
	{
		Root.Context.Update(TimeSpan((int64)((double)seconds * (double)TimeSpan.TicksPerSecond)));
		Root.UpdateLayout();
	}

	public void Pause() => Frame(1.0f);

	/// Its text, appended to `outText`.
	public String Text(String outText)
	{
		Editor.GetText(outText);
		return outText;
	}

	/// Asserts its text is `expected`, saying what it is when it is not.
	public void CheckText(StringView expected)
	{
		let text = Text(.. scope String());
		Test.Assert(text == expected, scope String()..AppendF("the text: \"{}\"", text));
	}

	public CodePosition Caret => Editor.Primary.Head;

	/// Types `text` a grapheme at a time.
	public void Type(StringView text)
	{
		var rest = text;
		while (rest.Length != 0)
		{
			let next = NextGrapheme(rest, 0);
			Editor.Type(rest.Substring(0, next));
			rest = rest.Substring(next, rest.Length - next);
		}
	}

	public void Key(KeyCode key, uint32 modifiers = 0)
	{
		D.InjectKeyDown((uint32)key, modifiers);
	}

	public bool Run(TextEditCommand command) => Editor.Run(command);

	/// A point over a position: its caret's middle (the editor at the root's origin).
	public Float2 Over(CodePosition at)
	{
		let caret = Editor.CaretRect(at);
		return .(caret.X + 1.0f, caret.Y + caret.Height * 0.5f);
	}

	/// A press and its release at `at`, the pointer moved there first.
	public void Click(Float2 at, uint32 modifiers = 0)
	{
		D.InjectMouseMove(at, modifiers);
		D.InjectMouseDown(at, .Left, modifiers);
		D.InjectMouseUp(at, .Left, modifiers);
	}
}

/// A script's few names; what it was last asked.
class Service : ICodeLanguageService
{
	public CodeCompletionRequest Last = .();
	public int Asked = 0;
	public int Hovered = 0;

	public StringView CompletionTriggers => ".";

	public void Complete(CodeDocument document, CodeCompletionRequest request, List<CodeCompletionItem> @out)
	{
		Last = request;
		++Asked;
		let items = @out;
		void Add(StringView label, CodeCompletionKind kind, StringView detail)
		{
			let item = new CodeCompletionItem();
			item.Label.Set(label);
			item.Kind = kind;
			item.Detail.Set(detail);
			items.Add(item);
		}
		Add("position", .Property, "Float3");
		Add("print", .Function, "void print(StringView text)");
		Add("pow", .Function, "float pow(float, float)");
		Add("Player", .Type, "class");
	}

	public bool Hover(CodeDocument document, CodePosition at, String @out)
	{
		++Hovered;
		let line = document.LineText(at.Line);
		if ((at.Column > 8) || (line.Length < 8) || (line.Substring(0, 8) != "position"))
			return false;
		@out.Set("Float3 position");
		return true;
	}
}

/// A bed in the editor's Beef with the test's service.
class CompletionBed : CodeBed
{
	public Service Service = new .() ~ delete _;

	public this(StringView text = default) : base("beef", text)
	{
		Editor.LanguageService = Service;
	}

	public ~this()
	{
		Editor.LanguageService = null; // the service goes first
	}

	public CodeCompletionList List => Editor.CompletionList;
	public StringView Shown(int i) => List.ShownItem(i).Label;

	public StringView Selected
	{
		get
		{
			let item = List.SelectedItem;
			return (item != null) ? (StringView)item.Label : default;
		}
	}
}
