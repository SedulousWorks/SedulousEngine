using System;
using System.Collections;
using System.Text;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The code editor driven through a REAL input manager: typing, navigation, the undo chords,
/// Tab arriving through WantsTabKey rather than moving focus, gutter clicks, the clipboard, the
/// find bar and completion.
class CodeEditViewTests
{
	private class TestClipboard : IClipboard
	{
		public String Stored = new .() ~ delete _;

		public Result<void> GetText(String outText)
		{
			outText.Set(Stored);
			return .Ok;
		}

		public Result<void> SetText(StringView text)
		{
			Stored.Set(text);
			return .Ok;
		}

		public bool HasText => !Stored.IsEmpty;
	}

	/// A laid out editor filling an eight hundred by six hundred root, focused and ready.
	private class Harness
	{
		public UIContext Context = new .() ~ delete _;
		public RootView Root;
		public CodeEditView View;
		public TestClipboard Clipboard = new .() ~ delete _;

		public this()
		{
			Root = new RootView();
			Root.ViewportSize = .(800, 600);
			Context.AddRootView(Root);
			Context.SetClipboard(Clipboard);

			View = new CodeEditView();
			Root.AddView(View);
			LayoutPass();
			Context.GetFocusManager().SetFocus(View);
		}

		public ~this()
		{
			Root.ReleaseRef();
		}

		public void LayoutPass()
		{
			Context.BeginFrame(0.016f);
			Root.Measure(BoxConstraints.Tight(800, 600));
			Root.Layout(0, 0, 800, 600);
		}

		public void Key(KeyCode key, KeyModifiers mods = .None) =>
			Context.GetInputManager().ProcessKeyDown(key, mods, false);

		public void Type(StringView text)
		{
			int index = 0;
			while (index < text.Length)
			{
				let codepoint = Utf8Text.DecodeAt(text, ref index);
				Context.GetInputManager().ProcessTextInput((char32)codepoint);
			}
		}

		/// View local coordinates of a buffer position. The view sits at the root's origin.
		public Float2 PointAt(int32 line, int32 column)
		{
			let x = View.GutterWidth + 6.0f + ((float)column * View.ColumnAdvance) + 1.0f;
			let y = 4.0f + (((float)line + 0.5f) * View.LineHeight);
			return .(x, y);
		}

		public void Click(int32 line, int32 column)
		{
			let p = PointAt(line, column);
			Context.GetInputManager().ProcessMouseMove(p.X, p.Y);
			Context.GetInputManager().ProcessMouseDown(.Left, p.X, p.Y, 0.0f);
			Context.GetInputManager().ProcessMouseUp(.Left, p.X, p.Y);
		}

		public void AssertText(StringView expected)
		{
			let actual = scope String();
			View.GetText(actual);
			Test.Assert(actual == expected, scope $"text was \"{actual}\"");
		}

		public void AssertSelection(StringView expected)
		{
			let actual = scope String();
			View.GetSelectedText(actual);
			Test.Assert(actual == expected, scope $"selection was \"{actual}\"");
		}
	}

	// ---- typing and navigation -----------------------------------------------------------------

	[Test]
	public static void TypingAndNewlineLandWhereTheCaretIs()
	{
		let h = scope Harness();
		h.Type("let x = 1");
		h.AssertText("let x = 1");
		Test.Assert(h.View.CursorPosition == CodePosition(0, 9));

		h.Key(.Return);
		h.Type("done");
		h.AssertText("let x = 1\ndone");
		Test.Assert(h.View.CursorPosition == CodePosition(1, 4));
	}

	[Test]
	public static void ANewlineCopiesTheLineIndent()
	{
		let h = scope Harness();
		h.Type("    indented");
		h.Key(.Return);
		Test.Assert(h.View.Document.Line(1) == "    ");
		Test.Assert(h.View.CursorPosition == CodePosition(1, 4));
	}

	/// The one language shaped rule in the key handling: an open brace earns an extra step.
	[Test]
	public static void ANewlineAfterAnOpenBraceIndentsOneStepFurther()
	{
		let h = scope Harness();
		h.Type("    if (x) {");
		h.Key(.Return);
		Test.Assert(h.View.Document.Line(1) == "        ");
	}

	[Test]
	public static void NavigationMovesByWordLineAndSelection()
	{
		let h = scope Harness();
		h.View.SetText("alpha beta\ngamma");

		h.Key(.Right, .Ctrl);
		Test.Assert(h.View.CursorPosition == CodePosition(0, 6));

		h.Key(.End, .Shift);
		h.AssertSelection("beta");

		// A plain arrow collapses to the selection's edge rather than moving one further.
		h.Key(.Left);
		Test.Assert(!h.View.HasSelection);
		Test.Assert(h.View.CursorPosition == CodePosition(0, 6));

		// The goal column survives a shorter line.
		h.Key(.End);
		h.Key(.Down);
		Test.Assert(h.View.CursorPosition == CodePosition(1, 5));
	}

	[Test]
	public static void HomeGoesToTheIndentThenToTheHardStart()
	{
		let h = scope Harness();
		h.View.SetText("    body");
		h.View.SetCursorPosition(.(0, 8));

		h.Key(.Home);
		Test.Assert(h.View.CursorPosition == CodePosition(0, 4));

		h.Key(.Home);
		Test.Assert(h.View.CursorPosition == CodePosition(0, 0));
	}

	/// Tab has to REACH the editor rather than move focus, which is what WantsTabKey buys.
	[Test]
	public static void TabIndentsInsteadOfMovingFocus()
	{
		let h = scope Harness();
		h.Type("a");
		h.Key(.Tab);
		Test.Assert(h.Context.GetFocusManager().FocusedView == h.View);
		Test.Assert(h.View.Document.Line(0) == "a   ", "to the four column stop");

		h.View.SetText("one\ntwo");
		h.View.SelectAll();
		h.Key(.Tab);
		Test.Assert(h.View.Document.Line(0) == "    one");
		Test.Assert(h.View.Document.Line(1) == "    two");

		h.Key(.Tab, .Shift);
		Test.Assert(h.View.Document.Line(0) == "one");
		Test.Assert(h.View.Document.Line(1) == "two");
	}

	[Test]
	public static void TheUndoChordsRunBothWays()
	{
		let h = scope Harness();
		h.Type("abc");

		h.Key(.Z, .Ctrl);
		h.AssertText("");

		h.Key(.Y, .Ctrl);
		h.AssertText("abc");

		h.Key(.Z, .Ctrl | .Shift); // Ctrl+Shift+Z redoes, and there is nothing to redo
		h.AssertText("abc");
	}

	[Test]
	public static void TheClipboardRoundTrips()
	{
		let h = scope Harness();
		h.View.SetText("copy me\nsecond");
		h.View.SetCursorPosition(.(0, 0));
		h.Key(.End, .Shift);
		h.Key(.C, .Ctrl);
		Test.Assert(h.Clipboard.Stored == "copy me");

		h.View.SetCursorPosition(.(1, 6));
		h.Key(.Return);
		h.Key(.V, .Ctrl);
		Test.Assert(h.View.Document.Line(2) == "copy me");

		h.View.SetCursorPosition(.(2, 0));
		h.Key(.End, .Shift);
		h.Key(.X, .Ctrl);
		Test.Assert(h.View.Document.Line(2).IsEmpty);
	}

	/// Ctrl+S belongs to the application. An editor that swallowed every chord would break
	/// save while it happened to be focused.
	[Test]
	public static void AnUnknownChordLeavesTheBufferAlone()
	{
		let h = scope Harness();
		h.Type("x");
		h.Context.GetInputManager().ProcessKeyDown(.S, .Ctrl, false);
		h.AssertText("x");
	}

	[Test]
	public static void ReadOnlyRefusesEveryEdit()
	{
		let h = scope Harness();
		h.View.SetText("locked");
		h.View.ReadOnly = true;
		h.Type("x");
		h.Key(.Backspace);
		h.Key(.Return);
		h.AssertText("locked");
	}

	// ---- mouse -----------------------------------------------------------------------------------

	[Test]
	public static void ClickingPlacesTheCaretAndDraggingSelects()
	{
		let h = scope Harness();
		h.View.SetText("alpha beta\ngamma");
		h.Click(1, 3);
		Test.Assert(h.View.CursorPosition == CodePosition(1, 3));

		let from = h.PointAt(0, 2);
		let to = h.PointAt(1, 2);
		h.Context.GetInputManager().ProcessMouseMove(from.X, from.Y);
		h.Context.GetInputManager().ProcessMouseDown(.Left, from.X, from.Y, 0.0f);
		h.Context.GetInputManager().ProcessMouseMove(to.X, to.Y);
		h.Context.GetInputManager().ProcessMouseUp(.Left, to.X, to.Y);
		h.AssertSelection("pha beta\nga");
	}

	[Test]
	public static void AClickInTheMarkerMarginTogglesABreakpoint()
	{
		let h = scope Harness();
		h.View.SetText("one\ntwo\nthree");

		int32 toggledLine = -1;
		var toggledSet = false;
		h.View.OnBreakpointToggled.Add(new [&toggledLine, &toggledSet](line, set) =>
			{
				toggledLine = line;
				toggledSet = set;
			});

		let y = 4.0f + (1.5f * h.View.LineHeight); // line one, in the marker margin
		h.Context.GetInputManager().ProcessMouseMove(6.0f, y);
		h.Context.GetInputManager().ProcessMouseDown(.Left, 6.0f, y, 0.0f);
		h.Context.GetInputManager().ProcessMouseUp(.Left, 6.0f, y);

		Test.Assert(toggledLine == 1);
		Test.Assert(toggledSet);
		Test.Assert(h.View.Document.MarkersOn(1).HasFlag(.Breakpoint));
	}

	/// The gutter is a click target, so it must not wear the I-beam, and neither may the
	/// scrollbars.
	[Test]
	public static void TheCursorChangesWithTheRegionUnderIt()
	{
		let h = scope Harness();
		h.View.SetText("one\ntwo");

		let text = h.PointAt(0, 2);
		h.Context.GetInputManager().ProcessMouseMove(text.X, text.Y);
		Test.Assert(h.Context.GetInputManager().CurrentCursor == .IBeam);

		h.Context.GetInputManager().ProcessMouseMove(6.0f, text.Y);
		Test.Assert(h.Context.GetInputManager().CurrentCursor == .Arrow);

		// Overflow vertically so the scrollbar child exists, then hover it.
		let longText = scope String();
		for (int32 i < 200)
			longText.Append("line\n");

		h.View.SetText(longText);
		h.LayoutPass();
		h.Context.GetInputManager().ProcessMouseMove(800.0f - 4.0f, 300.0f);
		Test.Assert(h.Context.GetInputManager().CurrentCursor == .Arrow);
	}

	/// THE INCIDENT: every Enter at the bottom edge advanced the scroll through
	/// EnsureCursorVisible, and then the vertical scrollbar, fed the new value BEFORE its
	/// maximum was updated, clamped it against the stale maximum and wrote the clamped value
	/// back. The caret line ended up half hidden below the edge.
	[Test]
	public static void TheCaretLineStaysFullyVisibleWhileTypingPastTheBottom()
	{
		let h = scope Harness();
		let lineH = h.View.LineHeight;
		let overflow = (int32)(600.0f / lineH) + 10;
		for (int32 i < overflow)
		{
			h.Key(.Return);
			h.LayoutPass();
		}

		let caretBottom = 4.0f + (((float)h.View.CursorPosition.Line + 1.0f) * lineH) -
			h.View.ScrollY;
		Test.Assert(caretBottom <= (h.View.Height + 0.01f));
		Test.Assert(caretBottom >= lineH, "and on screen at all, not scrolled past");
	}

	// ---- find, replace and go to line ------------------------------------------------------------

	[Test]
	public static void TheFindBarSearchesLiveAndNavigatesWithWrapping()
	{
		let h = scope Harness();
		h.View.SetText("alpha beta\nalpha gamma\nend alpha");

		h.Key(.F, .Ctrl);
		Test.Assert(h.View.FindBar == .Find);
		// Focus moved into the bar's field, so typing lands there and the search runs live.
		Test.Assert(h.Context.GetFocusManager().FocusedView != h.View);

		h.Type("alpha");
		Test.Assert(h.View.SearchMatches.Length == 3);
		Test.Assert(h.View.CurrentMatchIndex == 0);
		h.AssertSelection("alpha");

		// F3 from the FIELD advances, which is the capture phase interplay.
		h.Key(.F3);
		Test.Assert(h.View.CurrentMatchIndex == 1);
		h.Key(.F3);
		h.Key(.F3);
		Test.Assert(h.View.CurrentMatchIndex == 0, "wrapped");
		h.Key(.F3, .Shift);
		Test.Assert(h.View.CurrentMatchIndex == 2);

		// Escape closes, clears the highlights and hands focus back.
		h.Key(.Escape);
		Test.Assert(h.View.FindBar == .Closed);
		Test.Assert(h.View.SearchMatches.Length == 0);
		Test.Assert(h.Context.GetFocusManager().FocusedView == h.View);
	}

	[Test]
	public static void ReplaceAllIsOneUndoStep()
	{
		let h = scope Harness();
		h.View.SetText("foo x foo\nfoo");
		h.View.OpenFindBar(true);
		h.View.SetSearchQuery("foo");
		h.View.SetReplaceText("barbar");
		Test.Assert(h.View.SearchMatches.Length == 3);

		h.View.ReplaceAll();
		h.AssertText("barbar x barbar\nbarbar");

		h.View.CloseFindBar();
		h.Key(.Z, .Ctrl);
		h.AssertText("foo x foo\nfoo");
	}

	[Test]
	public static void GoToLineJumpsToAOneBasedLine()
	{
		let h = scope Harness();
		let text = scope String();
		for (int32 i < 50)
			text.Append("line\n");

		h.View.SetText(text);
		h.Key(.G, .Ctrl);
		Test.Assert(h.View.FindBar == .GoToLine);

		h.Type("42");
		h.Key(.Return);
		Test.Assert(h.View.FindBar == .Closed);
		Test.Assert(h.View.CursorPosition.Line == 41);
	}

	// ---- the comment toggle -----------------------------------------------------------------------

	[Test]
	public static void TheCommentToggleUsesTheLexersPrefixAndSkipsBlankLines()
	{
		let h = scope Harness();
		h.View.SetLexer(new CLikeLexer(.())); // its line comment prefix is two slashes
		h.View.SetText("one\n\ntwo");
		h.View.SelectAll();

		h.Key(.Slash, .Ctrl);
		Test.Assert(h.View.Document.Line(0) == "// one");
		Test.Assert(h.View.Document.Line(1) == "", "a blank line is untouched");
		Test.Assert(h.View.Document.Line(2) == "// two");

		// The toggle leaves the lines selected, so a second press comes straight back off.
		h.Key(.Slash, .Ctrl);
		Test.Assert(h.View.Document.Line(0) == "one");
		Test.Assert(h.View.Document.Line(2) == "two");

		// One undo step per toggle.
		h.Key(.Z, .Ctrl);
		Test.Assert(h.View.Document.Line(0) == "// one");
	}

	/// Markup has only block comments. Guessing a marker would corrupt the file quietly.
	[Test]
	public static void TheCommentToggleIsANoOpForMarkup()
	{
		let h = scope Harness();
		h.View.SetLexer(new XmlLexer());
		h.View.SetText("<a/>");
		h.Key(.Slash, .Ctrl);
		h.AssertText("<a/>");
	}

	// ---- tooltips -----------------------------------------------------------------------------------

	[Test]
	public static void AHoverValueWinsAndADiagnosticIsTheFallback()
	{
		let h = scope Harness();
		h.View.SetText("var speed = 4\nplain");
		h.View.HoverValueProvider = new (identifier, outValue) =>
			{
				if (identifier == "speed")
					outValue.Set("4 : Num");
			};

		let onWord = h.PointAt(0, 5); // inside "speed"
		h.Context.GetInputManager().ProcessMouseMove(onWord.X, onWord.Y);
		let value = h.View.CreateTooltipContent();
		Test.Assert(value != null);
		value.ReleaseRef();

		// An unknown word yields nothing, and the line carries no diagnostic either.
		let onPlain = h.PointAt(1, 2);
		h.Context.GetInputManager().ProcessMouseMove(onPlain.X, onPlain.Y);
		Test.Assert(h.View.CreateTooltipContent() == null);

		let diagnostics = new List<CodeDiagnostic>();
		diagnostics.Add(new CodeDiagnostic(true, 1, "broken"));
		h.View.Document.SetDiagnostics(diagnostics);

		h.Context.GetInputManager().ProcessMouseMove(onPlain.X, onPlain.Y);
		let fallback = h.View.CreateTooltipContent();
		Test.Assert(fallback != null);
		fallback.ReleaseRef();
	}

	[Test]
	public static void ADiagnosticLineHasATooltipAndACleanLineDoesNot()
	{
		let h = scope Harness();
		h.View.SetText("ok line\nbad line");

		let diagnostics = new List<CodeDiagnostic>();
		diagnostics.Add(new CodeDiagnostic(true, 1, "something broke"));
		h.View.Document.SetDiagnostics(diagnostics);

		let bad = h.PointAt(1, 2);
		h.Context.GetInputManager().ProcessMouseMove(bad.X, bad.Y);
		let content = h.View.CreateTooltipContent();
		Test.Assert(content != null);
		content.ReleaseRef();

		let good = h.PointAt(0, 2);
		h.Context.GetInputManager().ProcessMouseMove(good.X, good.Y);
		Test.Assert(h.View.CreateTooltipContent() == null);
	}

	// ---- completion ------------------------------------------------------------------------------

	[Test]
	public static void CompletionOpensFiltersAndAccepts()
	{
		let h = scope Harness();
		h.View.SetText("counter = 0\ncontinue_run = 1\n");
		h.View.SetCursorPosition(h.View.Document.EndPosition);

		// Two identifier characters auto open the popup with both harvested words.
		h.Type("co");
		Test.Assert(h.View.Completion.IsOpen);
		Test.Assert(h.View.Completion.ItemCount == 2);

		// Down then Enter accepts the second, which sorts continue_run before counter.
		h.Key(.Down);
		h.Key(.Return);
		Test.Assert(!h.View.Completion.IsOpen);
		Test.Assert(h.View.Document.Line(2) == "counter");

		// Escape dismisses without inserting.
		h.Key(.Return);
		h.Type("co");
		Test.Assert(h.View.Completion.IsOpen);
		h.Key(.Escape);
		Test.Assert(!h.View.Completion.IsOpen);
		Test.Assert(h.View.Document.Line(3) == "co");
	}

	/// Records the prefix it was asked for, and answers with one fixed candidate.
	private class ProbeProvider : ICompletionProvider
	{
		public String LastPrefix = new .() ~ delete _;
		public int32 Calls = 0;

		public void Collect(CodeDocument document, CodePosition cursor, StringView prefix,
			List<CompletionCandidate> outCandidates)
		{
			Calls++;
			LastPrefix.Set(prefix);
			outCandidates.Add(new CompletionCandidate("Member", "Member"));
		}
	}

	[Test]
	public static void ATriggerCharacterOpensCompletionWithAnEmptyPrefix()
	{
		let h = scope Harness();
		let probe = scope ProbeProvider();
		h.View.AddCompletionProvider(probe);
		h.View.DocumentWordCompletion = false;

		h.Type("x.");
		Test.Assert(h.View.Completion.IsOpen);
		Test.Assert(probe.LastPrefix.IsEmpty);
		Test.Assert(h.View.Completion.ItemCount == 1);
		Test.Assert(h.View.Completion.Item(0).Label == "Member");

		h.Key(.Return);
		h.AssertText("x.Member");

		// THE RANKING: provider results sort ABOVE the document's own words even when a word
		// is capitalised. Plain alphabetical order would put every capitalised identifier
		// first and bury the context results below the popup's fold.
		h.View.DocumentWordCompletion = true;
		h.View.SetText("Aardvark Banana\ny.");
		h.View.SetCursorPosition(.(1, 2));
		h.View.RequestCompletion();
		Test.Assert(h.View.Completion.IsOpen);
		Test.Assert(h.View.Completion.Item(0).Label == "Member");
	}

	[Test]
	public static void MarkupCompletionOffersElementsThenAttributes()
	{
		MarkupLoader.Initialize();

		let provider = scope MarkupCompletionProvider();
		let doc = scope CodeDocument();
		let candidates = scope List<CompletionCandidate>();
		defer { ClearAndDeleteItems!(candidates); }

		bool contains(List<CompletionCandidate> items, StringView name)
		{
			for (let item in items)
			{
				if (StringView(item.Label) == name)
					return true;
			}

			return false;
		}

		// Element position: right after the angle bracket.
		doc.SetText("<La");
		provider.Collect(doc, .(0, 3), "La", candidates);
		Test.Assert(contains(candidates, "Label"));
		Test.Assert(contains(candidates, "Flex"));

		// Attribute position: past the element name.
		ClearAndDeleteItems!(candidates);
		doc.SetText("<Label tex");
		provider.Collect(doc, .(0, 10), "tex", candidates);
		Test.Assert(contains(candidates, "text"));
		Test.Assert(!contains(candidates, "Label"), "element names are not attributes");

		// Plain text between tags offers nothing.
		ClearAndDeleteItems!(candidates);
		doc.SetText("<Label>hello");
		provider.Collect(doc, .(0, 12), "hello", candidates);
		Test.Assert(candidates.Count == 0);
	}

	// ---- the completion model on its own ----------------------------------------------------------

	private static void Fill(List<CompletionCandidate> items, params StringView[] labels)
	{
		for (let label in labels)
			items.Add(new CompletionCandidate(label, label));
	}

	[Test]
	public static void TheModelRanksExactCaseMatchesFirst()
	{
		let items = scope List<CompletionCandidate>();
		Fill(items, "Count", "counter", "other");

		let model = scope CompletionModel();
		model.Open(.(0, 0), items, "co");
		Test.Assert(model.IsOpen);
		Test.Assert(model.ItemCount == 2);
		Test.Assert(model.Item(0).Label == "counter");
		Test.Assert(model.Item(1).Label == "Count");

		// Filtering down to nothing closes the popup.
		model.Filter("cox");
		Test.Assert(!model.IsOpen);
	}

	[Test]
	public static void TheModelClosesWhenTheOnlyMatchIsThePrefix()
	{
		let items = scope List<CompletionCandidate>();
		Fill(items, "done");

		let model = scope CompletionModel();
		model.Open(.(0, 0), items, "done");
		Test.Assert(!model.IsOpen, "nothing left to complete");
	}

	[Test]
	public static void TheModelRoutesItsOwnKeysAndGoesInertWhenClosed()
	{
		let items = scope List<CompletionCandidate>();
		Fill(items, "aaa", "bbb");

		let model = scope CompletionModel();
		model.Open(.(0, 0), items, "a");

		Test.Assert(model.HandleKey(.Down) == .Consumed);
		Test.Assert(model.HandleKey(.Up) == .Consumed);
		Test.Assert(model.HandleKey(.Left) == .Ignored);
		Test.Assert(model.HandleKey(.Tab) == .Accepted);
		Test.Assert(model.HandleKey(.Escape) == .Dismissed);
		Test.Assert(!model.IsOpen);
		Test.Assert(model.HandleKey(.Down) == .Ignored);
	}

	/// The seam for external inserters: an API browser or a snippet lands as ONE action, not
	/// as a run of keystrokes to undo one at a time.
	[Test]
	public static void InsertAtCursorIsOneDiscreteUndoUnit()
	{
		let h = scope Harness();
		h.Type("call ");
		h.View.InsertAtCursor("Float3");
		h.AssertText("call Float3");
		Test.Assert(h.View.CursorPosition == CodePosition(0, 11));

		// It replaces a selection, and an empty string does nothing at all.
		h.View.SetCursorPosition(.(0, 5));
		h.Key(.End, .Shift);
		h.View.InsertAtCursor("Quaternion");
		h.AssertText("call Quaternion");
		h.View.InsertAtCursor("");
		h.AssertText("call Quaternion");

		h.Key(.Z, .Ctrl);
		h.AssertText("call Float3");
	}

	/// The last case from the lexer suite: the view forwards its document's changes to its own
	/// highlighter, so tokens stay queryable across edits.
	[Test]
	public static void TheLexerIsWiredThroughEdits()
	{
		let h = scope Harness();
		CLikeLexerSpec spec = .();
		spec.Keywords = TestKeywords;
		h.View.SetLexer(new CLikeLexer(spec));
		h.View.SetText("var a = 1");

		h.View.Highlighter.EnsureLexed(h.View.Document, 0);
		Test.Assert(h.View.Highlighter.TokensFor(0).Length > 0);
		Test.Assert(h.View.Highlighter.TokensFor(0)[0].Kind == .Keyword);

		CodeCursorState before = .();
		h.View.Document.Edit(.(.(0, 0), .(0, 3)), "class", .Other, before, 0.0);
		h.View.Highlighter.EnsureLexed(h.View.Document, 0);
		Test.Assert(h.View.Highlighter.TokensFor(0)[0].Kind == .Keyword, "\"class\" now");
	}

	private static StringView[4] TestKeywords = .("class", "if", "return", "var");
}
