using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The code editor's view over a CodeDocument (its own, or one its host shares). Each line in view
// is shaped with the GUI's text and kept until its text changes (foundation.ui's editor drew every
// token each frame, fixed pitch, so tabs and wide characters misaligned); tabs go to tab stops in
// what is shown, and the caret and the mouse go by the shaped places, so any font serves. Code runs
// left to right in every language, a string's Arabic still shaped. Only the rows in view are drawn;
// the editor is a scroll container over its lines, the core's bars and wheel scrolling it.
//
// Several selections from the start, sorted and apart (zed's): a click places one caret, Shift
// extends it, Alt adds one; a double click selects a word, a triple a line, a drag extends by what
// the press selected. The keys are the keymap's text commands (the arrows, Home and End, the word
// and page moves, deleting, undo, the clipboard), bound in its own "codeeditor" context by
// BindCodeEditorKeys, each run at every caret; typing goes in at each, one undo step that puts every
// caret back; Return keeps the line's indent; Tab indents; Escape leaves one caret. The gutter
// numbers the lines.
//
// Given a language, each line's tokens are kept with the state it began in and its hash, and a line
// is tokenized again only where it changed or the line before now ends otherwise; tokenizing runs to
// the last line in view. Each token draws in its part's colour (`codeeditor::keyword { color: ...
// }`), so a theme restyles code.
//
// Given its host's language service, a name typed (or a trigger, or Ctrl+Space) opens the
// completion list below the word, a popup that leaves it the focus; while it shows, the editor
// declares "completing" beside "codeeditor", so the list's keys win; the service's word under the
// pointer joins the tooltip after the diagnostics.
//
// Folding: ranges from the language's brackets, its indentation or its regions, or the host's; a
// folded range's lines hide. Soft wrap breaks long lines at the view's width. One map from lines to
// rows serves the carets, the pointer, the scroll and the drawing, so a fold is one row and a
// wrapped line several. Whitespace is drawn by VS Code's choices (none, boundary, selection,
// trailing, all).

static
{
	// The code editor's own commands, bound in its "codeeditor" key context.
	public const String cCodeToggleComment = "code.toggle-comment";
	public const String cCodeIndentLines = "code.indent-lines";
	public const String cCodeOutdentLines = "code.outdent-lines";
	public const String cCodeMoveLinesUp = "code.move-lines-up";
	public const String cCodeMoveLinesDown = "code.move-lines-down";
	public const String cCodeDuplicateLinesUp = "code.duplicate-lines-up";
	public const String cCodeDuplicateLinesDown = "code.duplicate-lines-down";
	public const String cCodeDeleteLines = "code.delete-lines";
	public const String cCodeAddNextOccurrence = "code.add-next-occurrence";
	public const String cCodeSelectAllOccurrences = "code.select-all-occurrences";
	public const String cCodeAddCursorAbove = "code.add-cursor-above";
	public const String cCodeAddCursorBelow = "code.add-cursor-below";
	public const String cCodeFind = "code.find";
	public const String cCodeReplace = "code.replace";
	public const String cCodeGoToLine = "code.go-to-line";
	public const String cCodeFindNext = "code.find-next";
	public const String cCodeFindPrevious = "code.find-previous";
	public const String cCodeComplete = "code.complete";
	public const String cCodeToggleSoftWrap = "code.toggle-soft-wrap";
	public const String cCodeToggleWhitespace = "code.toggle-whitespace";
	public const String cCodeFold = "code.fold";
	public const String cCodeUnfold = "code.unfold";
	public const String cCodeFoldAll = "code.fold-all";
	public const String cCodeUnfoldAll = "code.unfold-all";
	public const String cCodeCompletionNext = "code.completion-next";
	public const String cCodeCompletionPrevious = "code.completion-previous";
	public const String cCodeCompletionPageDown = "code.completion-page-down";
	public const String cCodeCompletionPageUp = "code.completion-page-up";
	public const String cCodeCompletionAccept = "code.completion-accept";
	public const String cCodeCompletionClose = "code.completion-close";

	/// Binds the code editor's keys (VS Code's), rebindable as any: a host calls it once for a GUI's
	/// keymap, after the GUI's own bindings (which then win a tie). The text editing keys and its own
	/// commands where the editor has the focus (not a field inside it); finding from its find bar's
	/// fields too.
	public static void BindCodeEditorKeys(Keymap keymap)
	{
		const String cItself = "codeeditor && !textinput";
		BindTextEditingKeys(keymap, cItself);
		for (let b in CodeEditorDetail.sBindings)
		{
			StringView command = b.Command;
			let finding = (command == cCodeFind) || (command == cCodeReplace) || (command == cCodeGoToLine) ||
				(command == cCodeFindNext) || (command == cCodeFindPrevious);
			keymap.Bind(b.Keys, command, finding ? "codeeditor" : cItself);
		}
		// The completion list's keys, in the context the editor declares while it shows; bound after
		// the editing keys, at the same depth they win. Tab accepts too (the editor's own key).
		for (let b in CodeEditorDetail.sListBindings)
			keymap.Bind(b.Keys, b.Command, "codeeditor && completing && !textinput");
	}

	public static StringView CodeSeverityName(CodeSeverity severity)
	{
		switch (severity)
		{
		case .Error: return "error";
		case .Warning: return "warning";
		case .Info: return "info";
		case .Hint: return "hint";
		}
	}
}

/// Which whitespace is drawn (VS Code's choices): a dot for a space, an arrow for a tab.
enum CodeWhitespace : uint8
{
	None,
	/// All but a single space between words.
	Boundary,
	/// What the selections hold.
	Selection,
	/// What ends a line.
	Trailing,
	All,
}

/// A fold: its first line stays in view; folded, the lines after it to its last hide.
struct CodeFoldRange : IEquatable<CodeFoldRange>
{
	public uint32 First = 0;
	public uint32 Last = 0;

	public this() { }

	public this(uint32 first, uint32 last)
	{
		First = first;
		Last = last;
	}

	public bool Equals(CodeFoldRange other) => this == other;

	[Commutable]
	public static bool operator==(CodeFoldRange a, CodeFoldRange o) => (a.First == o.First) && (a.Last == o.Last);
}

/// How bad a diagnostic is: each draws in its part's colour (`codeeditor::error`).
enum CodeSeverity : uint8
{
	Hint,
	Info,
	Warning,
	Error,
}

/// What a host says of a run of the code: a compiler's error, a warning. A class: it owns its
/// message; Set copies another.
class CodeDiagnostic
{
	public CodeRange Range = .();
	public CodeSeverity Severity = .Error;
	public String Message = new .() ~ delete _;

	public this() { }

	public this(CodeRange range, CodeSeverity severity, StringView message)
	{
		Range = range;
		Severity = severity;
		Message.Set(message);
	}

	/// Makes this a copy of `other`.
	public void Set(CodeDiagnostic other)
	{
		if (other === this)
			return;
		Range = other.Range;
		Severity = other.Severity;
		Message.Set(other.Message);
	}
}

[GuiReflect(true)]
class CodeEditor : UIWidget
{
	public const float cBlinkSeconds = 0.5f;
	/// A longer line is cut where it is laid out.
	public const uint32 cLongestLaidOut = 4096;

	private const float cGutterPad = 6.0f;
	/// The gutter's start: markers and diagnostics' icons.
	private const float cMarkerColumn = 16.0f;
	private const float cTextGap = 8.0f;
	/// The gutter's end: a fold's chevron.
	private const float cFoldColumn = 14.0f;

	private class LineLex
	{
		public uint64 Hash = 0;
		public CodeLexState Entry = .();
		public CodeLexState Exit = .();
		public List<CodeSpan> Spans = new .() ~ delete _;
		/// Raised each time it is tokenized.
		public uint64 Stamp = 0;
		public bool Valid = false;
	}

	private class LineView
	{
		public uint64 Hash = 0;
		public uint32 TabSize = 0;
		public uint64 LexStamp = uint64.MaxValue;
		public bool Laid = false;
		/// The line with its tabs to their stops (cut when very long).
		public String Shown = new .() ~ delete _;
		/// A byte column's place in Shown (empty: the same).
		public List<uint32> ShownAt = new .() ~ delete _;
		public Sedulous.GUI.Text Glyphs = new .() ~ delete _;
		public Sedulous.GUI.Text Number = new .() ~ delete _;
		public uint32 NumberOf = uint32.MaxValue;
	}

	// Where a position is: across (the text's own space) and its row.
	private struct Place
	{
		public float X = 0.0f;
		public uint32 Row = 0;

		public this(float x, uint32 row)
		{
			X = x;
			Row = row;
		}
	}

	// An edit planned against the text as it is.
	private class Planned
	{
		public CodeRange Range = .();
		public String Text = new .() ~ delete _;

		public this(CodeRange range, StringView text)
		{
			Range = range;
			Text.Set(text);
		}
	}

	private class Marker
	{
		public uint32 Id = 0;
		public CodeAnchorId Anchor = 0;
		public String Kind = new .() ~ delete _;
	}

	private class Diagnostic
	{
		public CodeAnchorId Start = 0;
		public CodeAnchorId End = 0;
		public CodeSeverity Severity = .Error;
		public String Message = new .() ~ delete _;
	}

	private struct OpenBracket
	{
		public char8 Close;
		public uint32 Line;

		public this(char8 close, uint32 line)
		{
			Close = close;
			Line = line;
		}
	}

	private struct OpenIndent
	{
		public uint32 Indent;
		public uint32 Line;

		public this(uint32 indent, uint32 line)
		{
			Indent = indent;
			Line = line;
		}
	}

	// Declared first, so it goes last: what it shows when no host shares one.
	private CodeDocument mOwn = new .() ~ delete _;
	private CodeDocument mDoc = null;
	private List<Marker> mMarkers = new .() ~ DeleteContainerAndItems!(_);
	private uint32 mLastMarker = 0;
	private List<Diagnostic> mDiagnostics = new .() ~ DeleteContainerAndItems!(_);
	private delegate void(uint32 line) mOnGutterClick ~ delete _;
	// The diagnostics under the pointer, and what the service says there.
	private String mHoverTip = new .() ~ delete _;
	private ICodeLanguageService mService = null;
	// Its child while open (a popup); a reference held.
	private CodeCompletionList mCompletion ~ _?.ReleaseRef();
	private bool mCompleting = false;
	// Where the word the list completes begins.
	private CodePosition mWordStart = .();
	// Folding: the ranges (the host's or computed), the folded (anchors on their first lines), and
	// each line's first row.
	private List<CodeFoldRange> mFoldRanges = new .() ~ delete _;
	private uint64 mFoldRangesVersion = uint64.MaxValue;
	private bool mHostFolds = false;
	private List<CodeFoldRange> mHostRanges = new .() ~ delete _;
	private List<CodeAnchorId> mFolded = new .() ~ delete _;
	private uint64 mFoldStamp = 0;
	private List<uint32> mRowStart = new .() ~ delete _;
	private uint64 mRowsVersion = uint64.MaxValue;
	private uint64 mRowsStamp = uint64.MaxValue;
	private float mRowsWrap = -1.0f;
	private uint32 mRowsTabSize = 0;
	private bool mWrap = false;
	private CodeWhitespace mWhitespace = .None;
	// The text's width, while wrapping.
	private float mWrapWidth = 0.0f;
	private bool mGutterHover = false;
	// A folded line's placeholder.
	private Sedulous.GUI.Text mFoldText = new .() ~ delete _;
	// It opened on no word (a trigger): an empty word keeps it.
	private bool mCompletedEmpty = false;
	// The word the service last spoke of.
	private CodeRange mHoverWord = .();
	private uint64 mHoverVersion = uint64.MaxValue;
	private String mHoverInfo = new .() ~ delete _;
	// Its change listener's token on mDoc.
	private uint32 mListener = 0;
	private CodeFindBar mFindBar ~ _?.ReleaseRef();
	private List<CodeRange> mMatches = new .() ~ delete _;
	private String mMatchesQuery = new .() ~ delete _;
	private uint64 mMatchesVersion = uint64.MaxValue;
	// Its owner's; not owned.
	private CodeLanguage mLanguage = null;
	// By line, tokenized up to the last line asked for.
	private List<LineLex> mLex = new .() ~ DeleteContainerAndItems!(_);
	// Lines before it agree with the lines before them.
	private uint32 mCleanTo = 0;
	private uint64 mTokenized = 0;
	private List<CodeSelection> mSelections = new .() ~ delete _;
	// Each selection's goal across, for Up and Down (below 0: none).
	private List<float> mGoals = new .() ~ delete _;
	private int mPrimary = 0;
	// By line, made as lines come into view (null until then).
	private List<LineView> mViews = new .() ~ DeleteContainerAndItems!(_);
	// The widest line laid out.
	private float mWidest = 0.0f;
	private float mEstimated = 0.0f;
	private uint64 mWidestVersion = uint64.MaxValue;
	// Ten digits: the gutter's width.
	private Sedulous.GUI.Text mMeasure = new .() ~ delete _;
	private delegate void(Sedulous.GUI.Text text) mStyleText ~ delete _;
	private String mComposition = new .() ~ delete _;
	private Sedulous.GUI.Text mCompositionText = new .() ~ delete _;
	private uint32 mTabSize = 4;
	private bool mInsertSpaces = true;
	private bool mReadOnly = false;
	private bool mCaretShown = true;
	private float mBlink = 0.0f;
	private bool mTicking = false;
	// A press's drag: what it began on and by what (1 a character, 2 a word, 3 a line).
	private bool mDragging = false;
	private uint32 mDragUnit = 1;
	private CodeRange mDragOrigin = .();
	private bool mDragAdds = false;
	// Where across it began (the text's own space).
	private float mColumnX = 0.0f;
	private uint32 mColumnLine = 0;

	public this()
	{
		Tag = "codeeditor";
		AccessRoleName = "textarea"; // what a screen reader takes it for
		TabFocusable = true;
		TabCaptures = true; // Tab indents
		// Its own context, not "textinput": a field inside it (the find bar's) is a text input alone,
		// its Return its own; BindCodeEditorKeys binds the editing keys here.
		KeyContext = "codeeditor";
		ClipChildren = true;
		ScrollsByKeys = false; // the arrows and pages move its carets, through the keymap
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.OverflowX = .Auto;
					s.OverflowY = .Auto;
				});
			Cursor = .Text;
		}
		for (int i < (int)TextEditCommand.Count)
		{
			let command = (TextEditCommand)i;
			OnCommand(TextEditCommandName(command), new (e) => { Run(command); });
		}
		OnCommand(cCodeToggleComment, new (e) => { ToggleComment(); });
		OnCommand(cCodeIndentLines, new (e) => { IndentLines(false); });
		OnCommand(cCodeOutdentLines, new (e) => { IndentLines(true); });
		OnCommand(cCodeMoveLinesUp, new (e) => { MoveLines(true); });
		OnCommand(cCodeMoveLinesDown, new (e) => { MoveLines(false); });
		OnCommand(cCodeDuplicateLinesUp, new (e) => { DuplicateLines(true); });
		OnCommand(cCodeDuplicateLinesDown, new (e) => { DuplicateLines(false); });
		OnCommand(cCodeDeleteLines, new (e) => { DeleteLines(); });
		OnCommand(cCodeAddNextOccurrence, new (e) => { AddNextOccurrence(); });
		OnCommand(cCodeSelectAllOccurrences, new (e) => { SelectAllOccurrences(); });
		OnCommand(cCodeAddCursorAbove, new (e) => { AddCursorVertically(true); });
		OnCommand(cCodeAddCursorBelow, new (e) => { AddCursorVertically(false); });
		OnCommand(cCodeFind, new (e) => { OpenFind(false); });
		OnCommand(cCodeReplace, new (e) => { OpenFind(true); });
		OnCommand(cCodeGoToLine, new (e) => { OpenGoToLine(); });
		OnCommand(cCodeFindNext, new (e) => { FindNext(false); });
		OnCommand(cCodeFindPrevious, new (e) => { FindNext(true); });
		OnCommand(cCodeComplete, new (e) => { TriggerCompletion(true); });
		OnCommand(cCodeFold, new (e) =>
			{
				let at = scope List<CodeSelection>()..AddRange(mSelections);
				for (let sel in at)
					Fold(sel.Head.Line);
			});
		OnCommand(cCodeUnfold, new (e) =>
			{
				let at = scope List<CodeSelection>()..AddRange(mSelections);
				for (let sel in at)
					Unfold(sel.Head.Line);
			});
		OnCommand(cCodeToggleSoftWrap, new (e) => { SoftWrap = !mWrap; });
		OnCommand(cCodeToggleWhitespace, new (e) => { ShowWhitespace = (mWhitespace == .None) ? .All : .None; });
		OnCommand(cCodeFoldAll, new (e) => { FoldAll(); });
		OnCommand(cCodeUnfoldAll, new (e) => { UnfoldAll(); });
		OnCommand(cCodeCompletionNext, new (e) => { mCompletion.MoveSelection(1, true); });
		OnCommand(cCodeCompletionPrevious, new (e) => { mCompletion.MoveSelection(-1, true); });
		OnCommand(cCodeCompletionPageDown, new (e) => { mCompletion.MoveSelection(CodeCompletionList.PageRows, false); });
		OnCommand(cCodeCompletionPageUp, new (e) => { mCompletion.MoveSelection(-CodeCompletionList.PageRows, false); });
		OnCommand(cCodeCompletionAccept, new (e) => { AcceptCompletion(); });
		OnCommand(cCodeCompletionClose, new (e) => { CloseCompletion(); });
		mFindBar = new CodeFindBar();
		mFindBar.SetOnChanged(new () => { FindChanged(); });
		mFindBar.SetOnNext(new (backwards) => { FindNext(backwards); });
		mFindBar.SetOnReplace(new (all) =>
			{
				if (all)
					ReplaceAll();
				else
					ReplaceCurrent();
			});
		mFindBar.SetOnGoTo(new (text) => { GoToLine(text); });
		mFindBar.SetOnClose(new () =>
			{
				RequestFocus();
				Invalidate();
			});
		AddChild(mFindBar);
		mCompletion = new CodeCompletionList();
		mCompletion.SetOnPicked(new (index) => { AcceptCompletion(); });
		Attach(mOwn);
		mSelections.Add(.());
		mGoals.Add(-1.0f);
	}

	public ~this()
	{
		Detach();
	}

	// === The document ===

	/// The document it edits: one shared with its host (which outlives it here), or its own; set to
	/// null, its own again.
	public CodeDocument Document
	{
		get => mDoc;
		set
		{
			Detach();
			Attach((value != null) ? value : mOwn);
			SetSelections(default);
		}
	}

	/// Replaces the text (undo starts again), one caret at the start.
	public void SetText(StringView text)
	{
		mDoc.SetText(text);
		SetSelections(default);
	}

	/// Its text, appended to `outText`.
	public void GetText(String outText) => mDoc.GetText(outText);

	/// The language its code is in (its owner keeps it, Prepared); null: plain text.
	public void SetLanguage(CodeLanguage language)
	{
		mFoldRangesVersion = uint64.MaxValue;
		++mFoldStamp;
		mLanguage = language;
		ClearAndDeleteItems!(mLex);
		mCleanTo = 0;
		ClearAndDeleteItems!(mViews);
		Invalidate();
	}

	public CodeLanguage GetLanguage() => mLanguage;

	/// Line `line`'s tokens (tokenizing up to it).
	public Span<CodeSpan> TokensOf(uint32 line)
	{
		if ((mLanguage == null) || (line >= mDoc.LineCount))
			return default;
		EnsureLexed(line);
		return mLex[(int)line].Spans;
	}

	/// How many lines have been tokenized since it began (each time a line was), for a test.
	public uint64 TokenizedCount => mTokenized;

	/// Whether it edits (or only shows, selects and copies).
	[GuiProperty("read-only")]
	public bool IsReadOnly
	{
		get => mReadOnly;
		set => mReadOnly = value;
	}

	/// Columns between tab stops (4).
	[GuiProperty("tab-size")]
	public uint32 TabSize
	{
		get => mTabSize;
		set
		{
			mTabSize = Math.Max((uint32)1, value);
			ClearAndDeleteItems!(mViews);
			RequestLayout();
			Invalidate();
		}
	}

	/// Whether Tab puts spaces (true) or a tab.
	public void SetInsertSpaces(bool spaces)
	{
		mInsertSpaces = spaces;
	}

	/// Long lines wrap at the view's width, a word too long for a row broken where it runs out; a
	/// wrapped line's rows are rows of the map, so Up and Down go by them.
	[GuiProperty("soft-wrap")]
	public bool SoftWrap
	{
		get => mWrap;
		set
		{
			if (value == mWrap)
				return;
			mWrap = value;
			ClearAndDeleteItems!(mViews);
			if (value)
				ScrollOffset = .(0.0f, ScrollOffset.Y);
			RequestLayout();
			Invalidate();
		}
	}

	/// Which whitespace it draws (none by default); its colour the `whitespace` part's.
	public CodeWhitespace ShowWhitespace
	{
		get => mWhitespace;
		set
		{
			mWhitespace = value;
			Invalidate();
		}
	}

	/// Whether the space or tab at `at` is drawn, by the choice.
	public bool ShowsWhitespaceAt(CodePosition at)
	{
		if ((mWhitespace == .None) || (at.Line >= mDoc.LineCount))
			return false;
		let text = mDoc.LineText(at.Line);
		let column = (int)at.Column;
		if ((column >= text.Length) || ((text[column] != ' ') && (text[column] != '\t')))
			return false;
		bool Blank(char8 c) => (c == ' ') || (c == '\t');
		switch (mWhitespace)
		{
		case .All:
			return true;
		case .Trailing:
			{
				for (int i = column; i < text.Length; ++i)
				{
					if (!Blank(text[i]))
						return false;
				}
				return true;
			}
		case .Boundary:
			{
				// A lone space with text either side is not drawn; a tab, a run, an indent or the
				// end's are.
				if (text[column] == '\t')
					return true;
				let before = (column > 0) && !Blank(text[column - 1]);
				let after = (column + 1 < text.Length) && !Blank(text[column + 1]);
				return !(before && after);
			}
		case .Selection:
			{
				for (let sel in mSelections)
				{
					let r = sel.Range;
					if (!sel.IsEmpty && (r.Start <= at) && (at < r.End))
						return true;
				}
				return false;
			}
		case .None:
			return false;
		}
	}

	// === Selections ===

	/// The selections, in the document's order, none overlapping.
	public Span<CodeSelection> Selections => mSelections;
	/// The one the keys and the view follow (the last added).
	public CodeSelection Primary => mSelections[mPrimary];

	/// Sets them (clamped, sorted, those that touch merged); none: one caret at the start.
	/// `primary`: the one the keys follow (out of range: the last).
	public void SetSelections(Span<CodeSelection> selections, int primary = -1)
	{
		mSelections.Clear();
		for (let s in selections)
			mSelections.Add(.(mDoc.Clamp(s.Anchor), mDoc.Clamp(s.Head)));
		if (mSelections.IsEmpty)
			mSelections.Add(.());
		mPrimary = ((primary >= 0) && (primary < mSelections.Count)) ? primary : mSelections.Count - 1;
		Normalize();
		ResetGoals();
		SelectionsChanged();
	}

	public void SetCaret(CodePosition at)
	{
		SetOnly(.(at, at));
	}

	/// Adds a caret (Alt+click's); it becomes the primary.
	public void AddCaret(CodePosition at)
	{
		let clamped = mDoc.Clamp(at);
		mSelections.Add(.(clamped, clamped));
		mPrimary = mSelections.Count - 1;
		Normalize();
		ResetGoals();
		SelectionsChanged();
	}

	// === Commands ===

	/// Runs a text command at every caret (what its keys do); false when it did nothing.
	public bool Run(TextEditCommand command)
	{
		let extend = (command == .SelectLeft) || (command == .SelectRight) || (command == .SelectWordLeft) || (command == .SelectWordRight) ||
			(command == .SelectLineStart) || (command == .SelectLineEnd) || (command == .SelectUp) || (command == .SelectDown) ||
			(command == .SelectPageUp) || (command == .SelectPageDown) || (command == .SelectDocumentStart) || (command == .SelectDocumentEnd);
		let doc = mDoc;
		switch (command)
		{
		case .MoveLeft, .SelectLeft:
			MoveEach(extend, scope (s, goal) =>
				{
					goal = -1.0f;
					return (!extend && !s.IsEmpty) ? s.Range.Start : doc.PreviousCharacter(s.Head);
				});
			return true;
		case .MoveRight, .SelectRight:
			MoveEach(extend, scope (s, goal) =>
				{
					goal = -1.0f;
					return (!extend && !s.IsEmpty) ? s.Range.End : doc.NextCharacter(s.Head);
				});
			return true;
		case .MoveWordLeft, .SelectWordLeft:
			MoveEach(extend, scope (s, goal) =>
				{
					goal = -1.0f;
					return WordLeft(s.Head);
				});
			return true;
		case .MoveWordRight, .SelectWordRight:
			MoveEach(extend, scope (s, goal) =>
				{
					goal = -1.0f;
					return WordRight(s.Head);
				});
			return true;
		case .MoveLineStart, .SelectLineStart:
			MoveEach(extend, scope (s, goal) =>
				{
					goal = -1.0f;
					return LineHome(s.Head);
				});
			return true;
		case .MoveLineEnd, .SelectLineEnd:
			MoveEach(extend, scope (s, goal) =>
				{
					goal = -1.0f;
					return CodePosition(s.Head.Line, (uint32)doc.LineText(s.Head.Line).Length);
				});
			return true;
		case .MoveUp, .SelectUp, .MoveDown, .SelectDown, .MovePageUp, .SelectPageUp, .MovePageDown, .SelectPageDown:
			{
				let up = (command == .MoveUp) || (command == .SelectUp) || (command == .MovePageUp) || (command == .SelectPageUp);
				let page = (command == .MovePageUp) || (command == .SelectPageUp) || (command == .MovePageDown) || (command == .SelectPageDown);
				let lines = (int32)((page ? PageLines() : 1) * (up ? -1 : 1));
				MoveEach(extend, scope (s, goal) => Vertical(s.Head, lines, ref goal));
				if (page)
				{
					var offset = ScrollOffset;
					offset.Y += (float)lines * LineHeight;
					ScrollOffset = offset;
					ScrollToCaret();
				}
				return true;
			}
		case .MoveDocumentStart, .SelectDocumentStart:
			MoveEach(extend, scope (s, goal) =>
				{
					goal = -1.0f;
					return CodePosition(0, 0);
				});
			return true;
		case .MoveDocumentEnd, .SelectDocumentEnd:
			MoveEach(extend, scope (s, goal) =>
				{
					goal = -1.0f;
					return doc.End();
				});
			return true;
		case .SelectAll:
			SetOnly(.(.(0, 0), doc.End()));
			return true;
		case .DeleteBackward, .DeleteForward, .DeleteWordBackward, .DeleteWordForward, .DeleteToLineStart, .DeleteToLineEnd:
			EditEach(.Deleting, scope (s, replaced, put, back) =>
				{
					if (!s.IsEmpty)
						replaced = s.Range;
					else if ((command == .DeleteBackward) && DeleteBackwardSpecial(s.Head, out replaced))
						return true;
					else
					{
						let at = s.Head;
						var other = at;
						switch (command)
						{
						case .DeleteBackward: other = doc.PreviousCharacter(at);
						case .DeleteForward: other = doc.NextCharacter(at);
						case .DeleteWordBackward: other = WordLeft(at);
						case .DeleteWordForward: other = WordRight(at);
						case .DeleteToLineStart: other = .(at.Line, 0);
						default: other = .(at.Line, (uint32)doc.LineText(at.Line).Length);
						}
						replaced = CodeRange.Ordered(at, other);
					}
					return !replaced.IsEmpty;
				});
			return true;
		case .InsertNewline:
			Newline();
			return true;
		case .Undo, .Redo:
			{
				let selections = scope List<CodeSelection>();
				let done = (command == .Undo) ? doc.Undo(selections) : doc.Redo(selections);
				if (done)
					SetSelections(selections);
				return done;
			}
		case .Cut:
			Copy(true);
			return true;
		case .Copy:
			Copy(false);
			return true;
		case .Paste:
			Paste();
			return true;
		default:
			return false;
		}
	}

	/// Types `text` at every caret, replacing what each selects (one undo step while typing goes on).
	/// One character in a language: auto-closed brackets and quotes (typing a close over the one put
	/// skips it), a selection surrounded, a closing word or mark first on its line outdenting it.
	public void Type(StringView text)
	{
		// One character, in a language that pairs or outdents: its own rules.
		if ((mLanguage != null) && (text.Length >= 1) && (text.Length <= 4) && (NextGrapheme(text, 0) == text.Length) && (text[0] != '\n'))
			TypeCharacter(text);
		else
		{
			EditEach(.Typing, scope (s, replaced, put, back) =>
				{
					replaced = s.Range;
					put.Set(text);
					return true;
				});
		}
		CompleteAfterTyping(text);
	}

	// === Its commands (each a command by name too, its keys in BindCodeEditorKeys) ===

	/// Comments the lines the selections cover, or uncomments them when all are (a block comment
	/// round each selection where the language has no line comment).
	public void ToggleComment()
	{
		if (mLanguage == null)
			return;
		let lang = mLanguage;
		let edits = scope List<Planned>();
		defer { ClearAndDeleteItems!(edits); }
		if (lang.LineComment.IsEmpty)
		{
			// Only block comments (markup's): round each selection, or its caret's line; off again
			// where a selection is one already.
			StringView open = lang.BlockComment.Open;
			StringView close = lang.BlockComment.Close;
			if (open.Length == 0)
				return;
			for (let sel in mSelections)
			{
				var r = sel.Range;
				if (r.IsEmpty)
				{
					let text = mDoc.LineText(r.Start.Line);
					r = .(.(r.Start.Line, IndentOf(text)), .(r.Start.Line, (uint32)text.Length));
				}
				let inside = mDoc.TextIn(r, .. scope String());
				StringView view = inside;
				if ((view.Length >= open.Length + close.Length) && (view.Substring(0, open.Length) == open) &&
					(view.Substring(view.Length - close.Length, close.Length) == close))
				{
					var body = view.Substring(open.Length, view.Length - open.Length - close.Length);
					if ((body.Length >= 2) && (body[0] == ' ') && (body[body.Length - 1] == ' '))
						body = body.Substring(1, body.Length - 2);
					edits.Add(new Planned(r, body));
				}
				else
				{
					let text = scope String(open);
					text.Append(" ");
					text.Append(view);
					text.Append(" ");
					text.Append(close);
					edits.Add(new Planned(r, text));
				}
			}
			ApplyPlanned(edits);
			return;
		}
		StringView mark = lang.LineComment;
		let firsts = scope List<uint32>();
		let lasts = scope List<uint32>();
		LineBlocks(firsts, lasts);
		// Off when every line with text is commented; else on, at the least indent.
		bool all = true;
		uint32 least = uint32.MaxValue;
		for (int b < firsts.Count)
		{
			for (uint32 line = firsts[b]; line <= lasts[b]; ++line)
			{
				let text = mDoc.LineText(line);
				let indent = IndentOf(text);
				if (indent == (uint32)text.Length)
					continue;
				least = Math.Min(least, indent);
				all = all && (text.Substring((int)indent, Math.Min(mark.Length, text.Length - (int)indent)) == mark);
			}
		}
		if (least == uint32.MaxValue)
			return; // only blank lines
		for (int b < firsts.Count)
		{
			for (uint32 line = firsts[b]; line <= lasts[b]; ++line)
			{
				let text = mDoc.LineText(line);
				let indent = IndentOf(text);
				if (indent == (uint32)text.Length)
					continue;
				if (all)
				{
					var cut = (uint32)mark.Length;
					if (((int)(indent + cut) < text.Length) && (text[(int)(indent + cut)] == ' '))
						++cut;
					edits.Add(new Planned(.(.(line, indent), .(line, indent + cut)), default));
				}
				else
				{
					let put = scope String(mark);
					put.Append(" ");
					edits.Add(new Planned(.(.(line, least), .(line, least)), put));
				}
			}
		}
		ApplyPlanned(edits);
	}

	/// Indents (or outdents) the lines the selections cover by a tab stop.
	public void IndentLines(bool outdent)
	{
		let firsts = scope List<uint32>();
		let lasts = scope List<uint32>();
		LineBlocks(firsts, lasts);
		let edits = scope List<Planned>();
		defer { ClearAndDeleteItems!(edits); }
		for (int b < firsts.Count)
		{
			for (uint32 line = firsts[b]; line <= lasts[b]; ++line)
			{
				let text = mDoc.LineText(line);
				let indent = IndentOf(text);
				if (!outdent)
				{
					if (indent < (uint32)text.Length) // a blank line keeps no indent
						edits.Add(new Planned(.(.(line, 0), .(line, 0)), IndentText(mTabSize, .. scope String())));
					continue;
				}
				// Up to a stop's worth of what indents it.
				uint32 columns = 0;
				uint32 bytes = 0;
				while ((bytes < indent) && (columns < mTabSize))
				{
					columns = (text[(int)bytes] == '\t') ? mTabSize : columns + 1;
					++bytes;
				}
				if (bytes > 0)
					edits.Add(new Planned(.(.(line, 0), .(line, bytes)), default));
			}
		}
		ApplyPlanned(edits);
	}

	/// Moves the lines the selections cover up or down past their neighbour.
	public void MoveLines(bool up)
	{
		let firsts = scope List<uint32>();
		let lasts = scope List<uint32>();
		LineBlocks(firsts, lasts);
		if (firsts.IsEmpty || (up && (firsts[0] == 0)) || (!up && (lasts.Back + 1 >= mDoc.LineCount)))
			return;
		// Each block and the line it passes, swapped as one edit; the selections a line along.
		CodePosition Shifted(CodePosition p) => .(up ? (uint32)(p.Line - 1) : (uint32)(p.Line + 1), p.Column);
		let before = scope List<CodeSelection>()..AddRange(mSelections);
		let after = scope List<CodeSelection>()..AddRange(mSelections);
		mDoc.Begin(before);
		for (int k < firsts.Count)
		{
			let b = up ? k : firsts.Count - 1 - k;
			let first = firsts[b];
			let last = lasts[b];
			let neighbour = up ? (uint32)(first - 1) : (uint32)(last + 1);
			let span = CodeRange(.(up ? neighbour : first, 0), .(up ? last : neighbour, (uint32)mDoc.LineText(up ? last : neighbour).Length));
			let block = mDoc.TextIn(.(.(first, 0), .(last, (uint32)mDoc.LineText(last).Length)), .. scope String());
			let other = scope String(mDoc.LineText(neighbour));
			let put = scope String(up ? block : other);
			put.Append("\n");
			put.Append(up ? other : block);
			mDoc.Replace(span, put);
			for (int i < after.Count)
			{
				let sel = after[i];
				if ((sel.Range.Start.Line >= first) && (sel.Range.End.Line <= last + 1))
					after[i] = .(Shifted(sel.Anchor), Shifted(sel.Head));
			}
		}
		mDoc.End(after);
		SetSelections(after, mPrimary);
	}

	/// Copies the lines the selections cover below (or above) them, the selections going with the
	/// copy.
	public void DuplicateLines(bool up)
	{
		let firsts = scope List<uint32>();
		let lasts = scope List<uint32>();
		LineBlocks(firsts, lasts);
		let before = scope List<CodeSelection>()..AddRange(mSelections);
		let after = scope List<CodeSelection>()..AddRange(mSelections);
		mDoc.Begin(before);
		for (int k = firsts.Count - 1; k >= 0; k--)
		{
			let first = firsts[k];
			let last = lasts[k];
			let count = (uint32)(last - first + 1);
			let block = mDoc.TextIn(.(.(first, 0), .(last, (uint32)mDoc.LineText(last).Length)), .. scope String());
			// The copy after the block's end: the selections go to it (down) or stay on the first (up).
			let put = scope String("\n");
			put.Append(block);
			mDoc.Insert(.(last, (uint32)mDoc.LineText(last).Length), put);
			for (int i < after.Count)
			{
				let sel = after[i];
				let inside = (sel.Range.Start.Line >= first) && (sel.Range.End.Line <= last);
				if (inside && !up)
					after[i] = .(.((uint32)(sel.Anchor.Line + count), sel.Anchor.Column), .((uint32)(sel.Head.Line + count), sel.Head.Column));
				else if (!inside && (sel.Range.Start.Line > last))
					after[i] = .(.((uint32)(sel.Anchor.Line + count), sel.Anchor.Column), .((uint32)(sel.Head.Line + count), sel.Head.Column));
			}
		}
		mDoc.End(after);
		SetSelections(after, mPrimary);
	}

	public void DeleteLines()
	{
		let firsts = scope List<uint32>();
		let lasts = scope List<uint32>();
		LineBlocks(firsts, lasts);
		let edits = scope List<Planned>();
		defer { ClearAndDeleteItems!(edits); }
		for (int b < firsts.Count)
		{
			let first = firsts[b];
			let last = lasts[b];
			if (last + 1 < mDoc.LineCount)
				edits.Add(new Planned(.(.(first, 0), .((uint32)(last + 1), 0)), default));
			else if (first > 0)
				edits.Add(new Planned(.(.((uint32)(first - 1), (uint32)mDoc.LineText((uint32)(first - 1)).Length), .(last, (uint32)mDoc.LineText(last).Length)), default));
			else
				edits.Add(new Planned(.(.(0, 0), mDoc.End()), default));
		}
		ApplyPlanned(edits);
	}

	/// Selects the primary caret's word, or adds a selection at the next match of the primary's text
	/// (Ctrl+D); false when there is none further.
	public bool AddNextOccurrence()
	{
		let primary = Primary;
		if (primary.IsEmpty)
		{
			// First, the word at the caret.
			let word = WordRangeAt(mDoc.LineText(primary.Head.Line), (int)primary.Head.Column);
			if (word.Start == word.End)
				return false;
			let one = CodeSelection(.(primary.Head.Line, (uint32)word.Start), .(primary.Head.Line, (uint32)word.End));
			let next = scope List<CodeSelection>()..AddRange(mSelections);
			next[mPrimary] = one;
			SetSelections(next, mPrimary);
			return true;
		}
		let needle = mDoc.TextIn(primary.Range, .. scope String());
		// From the last selection's end, round to the start; one already selected is skipped.
		var from = mSelections.Back.Range.End;
		for (int tries = 0; tries <= mSelections.Count; ++tries)
		{
			if (!mDoc.Find(needle, from, true, false, true, let found))
				return false;
			bool taken = false;
			for (let sel in mSelections)
				taken = taken || (sel.Range == found);
			if (!taken)
			{
				mSelections.Add(.(found.Start, found.End));
				mPrimary = mSelections.Count - 1;
				Normalize();
				ResetGoals();
				SelectionsChanged();
				return true;
			}
			from = found.End;
		}
		return false;
	}

	/// Selects every match of the primary selection's text (Ctrl+Shift+L).
	public void SelectAllOccurrences()
	{
		if (Primary.IsEmpty && !AddNextOccurrence())
			return;
		let needle = mDoc.TextIn(Primary.Range, .. scope String());
		let all = scope List<CodeSelection>();
		var from = CodePosition(0, 0);
		while (mDoc.Find(needle, from, true, false, false, let found))
		{
			all.Add(.(found.Start, found.End));
			from = (found.End == found.Start) ? mDoc.NextCharacter(found.End) : found.End;
			if (found.End == mDoc.End())
				break;
		}
		if (!all.IsEmpty)
			SetSelections(all);
	}

	/// Adds a caret a line above (or below) the primary, at its goal across.
	public void AddCursorVertically(bool up)
	{
		var goal = mGoals[mPrimary];
		let from = Primary.Head;
		if ((up && (from.Line == 0)) || (!up && (from.Line + 1 >= mDoc.LineCount)))
			return;
		let at = Vertical(from, up ? -1 : 1, ref goal);
		mSelections.Add(.(at, at));
		mPrimary = mSelections.Count - 1;
		Normalize();
		ResetGoals();
		mGoals[mPrimary] = goal;
		SelectionsChanged();
	}

	/// The bracket at or before `at` (not in a string or comment) and the one matching it.
	public bool FindMatchingBracket(CodePosition at, out CodeRange bracket, out CodeRange match)
	{
		bracket = .();
		match = .();
		if ((mLanguage == null) || mLanguage.Brackets.IsEmpty)
			return false;
		let place = mDoc.Clamp(at);
		bool Skip(CodeToken t) => (t == .String) || (t == .Comment) || (t == .Escape);
		// The bracket after the caret, else the one before it.
		for (int side = 0; side < 2; ++side)
		{
			let line = mDoc.LineText(place.Line);
			if ((side == 1) && (place.Column == 0))
				break;
			for (let pair in mLanguage.Brackets)
			{
				for (int which = 0; which < 2; ++which)
				{
					StringView mark = (which == 0) ? pair.Open : pair.Close;
					let column = (side == 0) ? place.Column : (uint32)(place.Column - (uint32)Math.Min(mark.Length, (int)place.Column));
					if ((mark.Length == 0) || ((int)column + mark.Length > line.Length) || (line.Substring((int)column, mark.Length) != mark) ||
						Skip(TokenAtColumn(place.Line, column)))
						continue;
					bracket = .(.(place.Line, column), .(place.Line, column + (uint32)mark.Length));
					// Out from it, its kind counted, past strings and comments, a few thousand lines at most.
					StringView open = pair.Open;
					StringView close = pair.Close;
					let forward = which == 0;
					int32 depth = 0;
					uint32 l = place.Line;
					int64 c = (int64)column;
					for (uint32 seen = 0; seen < 4000; ++seen)
					{
						let text = mDoc.LineText(l);
						while (forward ? (c < (int64)text.Length) : (c >= 0))
						{
							let col = (uint32)c;
							let isOpen = ((int)col + open.Length <= text.Length) && (text.Substring((int)col, open.Length) == open);
							let isClose = ((int)col + close.Length <= text.Length) && (text.Substring((int)col, close.Length) == close);
							if ((isOpen || isClose) && !Skip(TokenAtColumn(l, col)))
							{
								depth += (isOpen == forward) ? 1 : -1;
								if (depth == 0)
								{
									let size = (uint32)(isOpen ? open.Length : close.Length);
									match = .(.(l, col), .(l, col + size));
									return true;
								}
							}
							c += forward ? 1 : -1;
						}
						if (forward ? (l + 1 >= mDoc.LineCount) : (l == 0))
							return false;
						l = forward ? (uint32)(l + 1) : (uint32)(l - 1);
						c = forward ? 0 : (int64)mDoc.LineText(l).Length - 1;
					}
					return false;
				}
			}
		}
		return false;
	}

	// === Find, replace, go to line ===

	/// Shows the bar to find (or replace), holding the primary selection's text when it is on one
	/// line.
	public void OpenFind(bool replace)
	{
		let r = Primary.Range;
		let text = scope String();
		if (!r.IsEmpty && (r.Start.Line == r.End.Line))
			mDoc.TextIn(r, text);
		mFindBar.Show(replace ? .Replace : .Find, text);
		RequestLayout();
	}

	public void OpenGoToLine()
	{
		mFindBar.Show(.GoToLine, scope String()..AppendF("{}", Primary.Head.Line + 1));
		RequestLayout();
	}

	public CodeFindBar FindBar => mFindBar;

	/// Selects the next match of the bar's text after the primary selection (the previous before
	/// it), round the document; false when there is none.
	public bool FindNext(bool backwards)
	{
		RefreshMatches();
		if (mMatches.IsEmpty)
		{
			UpdateCount();
			return false;
		}
		let from = Primary.Range;
		int pick = 0;
		if (!backwards)
		{
			pick = 0; // round to the first when none follows
			for (int i < mMatches.Count)
			{
				if ((from.End <= mMatches[i].Start) && !(mMatches[i] == from))
				{
					pick = i;
					break;
				}
			}
		}
		else
		{
			pick = mMatches.Count - 1; // round to the last when none comes before
			for (int i = mMatches.Count - 1; i >= 0; i--)
			{
				if ((mMatches[i].End <= from.Start) && !(mMatches[i] == from))
				{
					pick = i;
					break;
				}
			}
		}
		SetOnly(.(mMatches[pick].Start, mMatches[pick].End));
		UpdateCount();
		return true;
	}

	/// Replaces the match the primary selection is on and finds the next; finds one first if it is
	/// on none.
	public void ReplaceCurrent()
	{
		if (mReadOnly || (CurrentMatch() == 0))
		{
			FindNext(false);
			return;
		}
		let edits = scope List<Planned>();
		defer { ClearAndDeleteItems!(edits); }
		edits.Add(new Planned(Primary.Range, mFindBar.Replacement));
		ApplyPlanned(edits);
		FindNext(false);
	}

	/// Replaces every match, one undo step.
	public void ReplaceAll()
	{
		RefreshMatches();
		if (mReadOnly || mMatches.IsEmpty)
			return;
		let edits = scope List<Planned>();
		defer { ClearAndDeleteItems!(edits); }
		for (let r in mMatches)
			edits.Add(new Planned(r, mFindBar.Replacement));
		ApplyPlanned(edits);
		UpdateCount();
	}

	/// Puts the caret at `line` or `line:column` (from 1), and closes the bar.
	public void GoToLine(StringView text)
	{
		// `line` or `line:column`, from 1.
		uint32 line = 0;
		uint32 column = 0;
		int at = 0;
		while ((at < text.Length) && (text[at] >= '0') && (text[at] <= '9'))
		{
			line = line * 10u + (uint32)((uint8)text[at] - (uint8)'0');
			++at;
		}
		if ((at < text.Length) && (text[at] == ':'))
		{
			++at;
			for (; (at < text.Length) && (text[at] >= '0') && (text[at] <= '9'); ++at)
				column = column * 10u + (uint32)((uint8)text[at] - (uint8)'0');
		}
		if (line == 0)
			return;
		mFindBar.Close();
		SetCaret(.((uint32)(line - 1), (column > 0) ? (uint32)(column - 1) : 0u));
		RequestFocus();
	}

	/// The matches of the bar's text now, in order.
	public Span<CodeRange> Matches
	{
		get
		{
			RefreshMatches();
			return mMatches;
		}
	}

	/// Which match the primary selection is on (from 1; 0: none).
	public int CurrentMatch()
	{
		RefreshMatches();
		for (int i < mMatches.Count)
		{
			if (mMatches[i] == Primary.Range)
				return i + 1;
		}
		return 0;
	}

	// === The gutter's markers, diagnostics ===

	/// Marks `line` as `kind` ("breakpoint", "execution", "bookmark", or a host's own, drawn by the
	/// `marker` part); the mark stays with its line through edits. An id for RemoveMarker.
	public uint32 AddMarker(uint32 line, StringView kind)
	{
		let marker = new Marker();
		marker.Id = ++mLastMarker;
		marker.Anchor = mDoc.AddAnchor(.(line, 0), .Right);
		marker.Kind.Set(kind);
		mMarkers.Add(marker);
		Invalidate();
		return mLastMarker;
	}

	public void RemoveMarker(uint32 id)
	{
		for (int i < mMarkers.Count)
		{
			if (mMarkers[i].Id == id)
			{
				mDoc.RemoveAnchor(mMarkers[i].Anchor);
				delete mMarkers[i];
				mMarkers.RemoveAt(i);
				Invalidate();
				return;
			}
		}
	}

	/// Takes away every mark of `kind` (empty: every mark).
	public void ClearMarkers(StringView kind = default)
	{
		for (int i = mMarkers.Count - 1; i >= 0; i--)
		{
			if ((kind.Length == 0) || (mMarkers[i].Kind == kind))
			{
				mDoc.RemoveAnchor(mMarkers[i].Anchor);
				delete mMarkers[i];
				mMarkers.RemoveAt(i);
			}
		}
		Invalidate();
	}

	/// The line a mark is on now.
	public uint32 MarkerLine(uint32 id)
	{
		for (let marker in mMarkers)
		{
			if (marker.Id == id)
				return mDoc.GetAnchor(marker.Anchor).Line;
		}
		return uint32.MaxValue;
	}

	public bool HasMarker(uint32 line, StringView kind)
	{
		for (let marker in mMarkers)
		{
			if ((marker.Kind == kind) && (mDoc.GetAnchor(marker.Anchor).Line == line))
				return true;
		}
		return false;
	}

	/// Told a click in the gutter's marker column, with its line (a host toggles a breakpoint
	/// there). OWNERSHIP of `callback` transfers.
	public void SetOnGutterClick(delegate void(uint32 line) callback)
	{
		delete mOnGutterClick;
		mOnGutterClick = callback;
	}

	/// Sets the diagnostics (a host's whole set, each time it has one); they keep their places
	/// through edits until the next set. The caller keeps `diagnostics`.
	public void SetDiagnostics(Span<CodeDiagnostic> diagnostics)
	{
		ClearDiagnosticAnchors();
		for (let d in diagnostics)
		{
			let r = CodeRange.Ordered(mDoc.Clamp(d.Range.Start), mDoc.Clamp(d.Range.End));
			let kept = new Diagnostic();
			kept.Start = mDoc.AddAnchor(r.Start, .Left);
			kept.End = mDoc.AddAnchor(r.End, .Right);
			kept.Severity = d.Severity;
			kept.Message.Set(d.Message);
			mDiagnostics.Add(kept);
		}
		Invalidate();
	}

	/// The diagnostics where they are now, each new (the caller owns them), added to
	/// `outDiagnostics`.
	public void GetDiagnostics(List<CodeDiagnostic> outDiagnostics)
	{
		for (let d in mDiagnostics)
			outDiagnostics.Add(new CodeDiagnostic(.(mDoc.GetAnchor(d.Start), mDoc.GetAnchor(d.End)), d.Severity, d.Message));
	}

	/// The worst severity on `line`; false when it has none.
	public bool WorstOn(uint32 line, out CodeSeverity @out)
	{
		@out = .Hint;
		bool any = false;
		for (let d in mDiagnostics)
		{
			let start = mDoc.GetAnchor(d.Start);
			let end = mDoc.GetAnchor(d.End);
			if ((start.Line <= line) && (line <= end.Line) && (!any || (d.Severity > @out)))
			{
				@out = d.Severity;
				any = true;
			}
		}
		return any;
	}

	/// The messages of the diagnostics over `at` (an empty one's word counting), a line each,
	/// appended to `outText`.
	public void DiagnosticsAt(CodePosition at, String outText)
	{
		bool any = false;
		for (let d in mDiagnostics)
		{
			let r = MarkedRange(d);
			if ((r.Start <= at) && (at <= r.End))
			{
				if (any)
					outText.Append("\n");
				outText.Append(d.Message);
				any = true;
			}
		}
	}

	/// On hover: the diagnostics under the pointer, else its own tooltip.
	public override StringView TooltipText => !mHoverTip.IsEmpty ? (StringView)mHoverTip : base.TooltipText;

	// === Folding ===

	/// The ranges that fold, by first line (one per line, the widest): the host's when it set them,
	/// else from the language: its brackets (outside strings and comments), or by indentation (a
	/// language that folds so, or none), and its regions. Set: the host's ranges in place of the
	/// language's (carried through edits until set again).
	public Span<CodeFoldRange> FoldRanges
	{
		get
		{
			EnsureFoldRanges();
			return mFoldRanges;
		}
		set
		{
			mHostFolds = true;
			mHostRanges.Clear();
			for (let r in value)
				mHostRanges.Add(r);
			mFoldRangesVersion = uint64.MaxValue;
			FoldsChanged();
		}
	}

	/// Back to the language's ranges.
	public void UseLanguageFolds()
	{
		mHostFolds = false;
		mHostRanges.Clear();
		mFoldRangesVersion = uint64.MaxValue;
		FoldsChanged();
	}

	/// Folds the innermost open range at `line` (starting on it, or holding it), its carets moved out
	/// to its first line. False when none is open there.
	public bool Fold(uint32 line)
	{
		EnsureFoldRanges();
		CodeFoldRange? best = null;
		for (let r in mFoldRanges)
		{
			if ((r.First <= line) && (line <= r.Last) && !IsFolded(r.First) && ((best == null) || (r.Last - r.First < best.Value.Last - best.Value.First)))
				best = r;
		}
		if (best == null)
			return false;
		FoldRange(best.Value);
		return true;
	}

	/// Unfolds every folded range holding `line` (or starting on it).
	public bool Unfold(uint32 line)
	{
		EnsureFoldRanges();
		bool any = false;
		for (int i = mFolded.Count - 1; i >= 0; i--)
		{
			let r = RangeStarting(mDoc.GetAnchor(mFolded[i]).Line);
			if ((r != null) && (r.Value.First <= line) && (line <= r.Value.Last))
			{
				mDoc.RemoveAnchor(mFolded[i]);
				mFolded.RemoveAt(i);
				any = true;
			}
		}
		if (any)
			FoldsChanged();
		return any;
	}

	/// Folds or unfolds the range starting on `line` (the gutter's click).
	public bool ToggleFold(uint32 line)
	{
		let r = RangeStarting(line);
		if (r == null)
			return false;
		if (!IsFolded(line))
		{
			FoldRange(r.Value);
			return true;
		}
		for (int i = mFolded.Count - 1; i >= 0; i--)
		{
			if (mDoc.GetAnchor(mFolded[i]).Line == line)
			{
				mDoc.RemoveAnchor(mFolded[i]);
				mFolded.RemoveAt(i);
			}
		}
		FoldsChanged();
		return true;
	}

	public void FoldAll()
	{
		EnsureFoldRanges();
		for (let r in mFoldRanges)
		{
			if (!IsFolded(r.First))
				mFolded.Add(mDoc.AddAnchor(.(r.First, 0), .Right));
		}
		FoldsChanged();
		CaretsOutOfFolds();
	}

	public void UnfoldAll()
	{
		for (let anchor in mFolded)
			mDoc.RemoveAnchor(anchor);
		mFolded.Clear();
		FoldsChanged();
	}

	public bool IsFolded(uint32 firstLine)
	{
		for (let anchor in mFolded)
		{
			if (mDoc.GetAnchor(anchor).Line == firstLine)
				return RangeStarting(firstLine) != null;
		}
		return false;
	}

	/// Inside a folded range, out of view.
	public bool IsLineHidden(uint32 line)
	{
		EnsureRows();
		return (line < mDoc.LineCount) && (mRowStart[(int)line + 1] == mRowStart[(int)line]);
	}

	/// The rows shown (each line in view one, with none hidden).
	public uint32 RowCount
	{
		get
		{
			EnsureRows();
			return mRowStart.Back;
		}
	}

	// === The language service ===

	/// What it asks for completions and for what to say of the word under the pointer: its host's,
	/// which outlives it here; null: none.
	public ICodeLanguageService LanguageService
	{
		get => mService;
		set
		{
			CloseCompletion();
			mService = value;
			mHoverVersion = uint64.MaxValue;
		}
	}

	/// Opens the completion list at the primary caret with the service's completions, filtered by
	/// the word before it: `invoked` (Ctrl+Space) anywhere, else as typed, not in a comment or a
	/// string, and only on a word begun or after a `trigger` character. False when none matched (or
	/// there is no service, or the caret selects).
	public bool TriggerCompletion(bool invoked, char8 trigger = 0)
	{
		if ((mService == null) || mReadOnly || !Primary.IsEmpty)
			return false;
		let at = mDoc.Clamp(Primary.Head);
		let start = WordStartBefore(at);
		if (!invoked)
		{
			// Typed: in code (not a comment or a string), on a word that is a name (not a number), or
			// just after a trigger.
			let token = TokenBefore(at);
			if ((token == .Comment) || (token == .String))
				return false;
			let text = mDoc.LineText(at.Line);
			if ((trigger == 0) && ((start.Column == at.Column) || ((text[(int)start.Column] >= '0') && (text[(int)start.Column] <= '9'))))
				return false;
		}
		var request = CodeCompletionRequest();
		request.At = at;
		request.WordStart = start;
		request.Invoked = invoked;
		request.Trigger = trigger;
		let items = scope List<CodeCompletionItem>();
		defer { ClearAndDeleteItems!(items); }
		mService.Complete(mDoc, request, items);
		mWordStart = start;
		mCompletedEmpty = start == at;
		let text = mDoc.LineText(at.Line);
		mCompletion.SetItems(items, text.Substring((int)start.Column, (int)at.Column - (int)start.Column));
		if (mCompletion.ShownCount == 0)
		{
			CloseCompletion();
			return false;
		}
		mCompleting = true;
		KeyContext = "codeeditor completing";
		PlaceCompletion();
		return true;
	}

	public bool IsCompleting => mCompleting;
	public CodeCompletionList CompletionList => mCompletion;

	/// Puts the selected completion in place of the word typed, at each caret where the same word is
	/// (else at the caret), as one undo step, and closes the list.
	public bool AcceptCompletion()
	{
		let item = mCompleting ? mCompletion.SelectedItem : null;
		StringView word = default;
		if ((item == null) || mReadOnly || !TypedWord(out word))
		{
			CloseCompletion();
			return false;
		}
		let insert = scope String(item.Insert.IsEmpty ? item.Label : item.Insert);
		let typed = scope String(word);
		CloseCompletion();
		mDoc.BreakMerge();
		EditEach(.Other, scope (s, replaced, put, back) =>
			{
				replaced = s.Range;
				if (s.IsEmpty && (s.Head.Column >= (uint32)typed.Length))
				{
					let line = mDoc.LineText(s.Head.Line);
					let from = (uint32)(s.Head.Column - (uint32)typed.Length);
					if (((int)s.Head.Column <= line.Length) && (line.Substring((int)from, typed.Length) == typed))
						replaced.Start.Column = from;
				}
				put.Set(insert);
				return true;
			});
		mDoc.BreakMerge();
		return true;
	}

	public void CloseCompletion()
	{
		let dispatcher = EventDispatcher;
		if ((dispatcher != null) && dispatcher.IsPopupOpen(mCompletion))
			dispatcher.ClosePopup(mCompletion);
		CompletionClosed();
	}

	/// What the service says of the word at `at` (empty off a word), asked once per word.
	public StringView HoverAt(CodePosition at)
	{
		if ((mService == null) || (at.Line >= mDoc.LineCount))
			return default;
		let text = mDoc.LineText(at.Line);
		var from = Math.Min(at.Column, (uint32)text.Length);
		var to = from;
		while ((from > 0) && IsWordByte(text[(int)from - 1]))
			--from;
		while (((int)to < text.Length) && IsWordByte(text[(int)to]))
			++to;
		let word = CodeRange(.(at.Line, from), .(at.Line, to));
		if (from == to)
			return default;
		if ((mHoverVersion != mDoc.Version) || !(mHoverWord.Start == word.Start) || !(mHoverWord.End == word.End))
		{
			mHoverVersion = mDoc.Version;
			mHoverWord = word;
			mHoverInfo.Clear();
			if (!mService.Hover(mDoc, at, mHoverInfo))
				mHoverInfo.Clear();
		}
		return mHoverInfo;
	}

	// === Geometry (its own space) ===

	public float LineHeight
	{
		get
		{
			let height = mMeasure.LineHeight;
			return (height > 0.0f) ? height : 16.0f;
		}
	}

	/// Where the text starts across: past the gutter and its gap.
	public float TextLeft => ContentBounds.X + GutterWidth;

	public float GutterWidth
	{
		get
		{
			uint32 digits = 1;
			for (uint32 n = mDoc.LineCount; n >= 10; n /= 10)
				++digits;
			return cMarkerColumn + (float)Math.Max(digits, 3u) * DigitWidth() + 2.0f * cGutterPad + cFoldColumn + cTextGap;
		}
	}

	/// The position nearest a point.
	public CodePosition PositionAt(Float2 local)
	{
		let content = ContentBounds;
		let shift = ScrollShift;
		let row = (local.Y - content.Y + shift.Y) / LineHeight;
		if (row < 0.0f)
			return .(0, 0);
		if ((uint32)row >= RowCount)
			return mDoc.End();
		uint32 sub = 0;
		let line = LineOfRow((uint32)row, &sub);
		return .(line, ColumnAt(line, sub, local.X - TextLeft + shift.X));
	}

	/// A position's caret: its left, top and the line's height.
	public Rect CaretRect(CodePosition at)
	{
		let clamped = mDoc.Clamp(at);
		let content = ContentBounds;
		let shift = ScrollShift;
		let lh = LineHeight;
		let place = PlaceOf(clamped);
		return .(TextLeft + place.X - shift.X, content.Y + (float)place.Row * lh - shift.Y, 1.5f, lh);
	}

	/// Scrolls by the least that shows the primary caret.
	public void ScrollToCaret()
	{
		let content = ContentBounds;
		if (content.Height <= 0.0f)
			return;
		let at = mDoc.Clamp(Primary.Head);
		let lh = LineHeight;
		var offset = ScrollOffset;
		let place = PlaceOf(at);
		let top = (float)place.Row * lh;
		if (top < offset.Y)
			offset.Y = top;
		else if (top + lh > offset.Y + content.Height)
			offset.Y = top + lh - content.Height;
		let x = place.X;
		let room = content.Width - GutterWidth;
		if (x < offset.X)
			offset.X = Math.Max(0.0f, x - room * 0.25f);
		else if (x + DigitWidth() > offset.X + room)
			offset.X = x + DigitWidth() - room + room * 0.25f;
		ScrollOffset = offset;
	}

	/// The lines in view now, first to last (inclusive).
	public void VisibleLines(out uint32 first, out uint32 last)
	{
		let content = ContentBounds;
		let top = ScrollShift.Y;
		let lh = LineHeight;
		let rows = RowCount;
		first = LineOfRow(Math.Min((uint32)Math.Max(0.0f, top / lh), (uint32)(rows - 1)));
		last = LineOfRow(Math.Min((uint32)Math.Max(0.0f, (top + content.Height) / lh), (uint32)(rows - 1)));
	}

	// Platform text input while focused, at the primary caret.
	public override bool WantsTextInput => IsTreeEnabled && !mReadOnly;

	public override bool GetTextInputArea(out Rect outArea, out float outCaretX)
	{
		let caret = CaretRect(Primary.Head);
		outArea = .(caret.X, caret.Y, Math.Max(1.0f, ComposedWidth()), caret.Height);
		outCaretX = caret.X;
		return true;
	}

	/// The current line, to a screen reader.
	[GuiProperty("", .None, "value")]
	public StringView AccessValue => mDoc.LineText(Primary.Head.Line);

	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("gutter");
		outParts.Add("line-number");
		outParts.Add("current-line-number");
		outParts.Add("current-line");
		outParts.Add("selection");
		outParts.Add("caret");
		outParts.Add("composition");
		outParts.Add("bracket-match");
		outParts.Add("find-match");
		outParts.Add("find-current");
		outParts.Add("fold");
		outParts.Add("fold-placeholder");
		outParts.Add("whitespace");
		for (let part in CodeEditorDetail.sMarks)
			outParts.Add(part);
		for (int i = 1; i < (int)CodeToken.Count; ++i)
			outParts.Add(CodeTokenName((CodeToken)i));
	}

	protected override void OnTextStyleChange()
	{
		delete mStyleText;
		mStyleText = new (text) =>
			{
				text.Font = Font;
				text.SetFontSelection(FontService, GetTextStyle().FontFamily, GetTextStyle().Selection);
				text.Color = TextColor;
				text.WhiteSpace = .Pre;
				text.Direction = ParagraphDirection(.LeftToRight, false);
			};
		mStyleText(mMeasure);
		mMeasure.SetString("0000000000");
		mStyleText(mFoldText);
		mFoldText.SetString("...");
		ClearAndDeleteItems!(mViews);
		RequestLayout();
		Invalidate();
	}

	// A token's colour changed: its lines are coloured again.
	protected override void OnPartStyleChange(StringView part)
	{
		base.OnPartStyleChange(part);
		ClearAndDeleteItems!(mViews);
		Invalidate();
	}

	public override void OnLayout()
	{
		// Not the base's: it places its one child (the find bar) itself, and its children's extent is
		// not what it scrolls over (laying them out would clamp the scroll to it). What it scrolls
		// over: every line down; across, the widest line laid out yet, else each line's length at the
		// width of a digit (an estimate a wider line laid out corrects).
		let digit = DigitWidth();
		if (mWidestVersion != mDoc.Version)
		{
			mWidestVersion = mDoc.Version;
			mEstimated = 0.0f;
			for (uint32 line = 0; line < mDoc.LineCount; ++line)
				mEstimated = Math.Max(mEstimated, (float)Math.Min(mDoc.LineText(line).Length, (int)cLongestLaidOut) * digit);
		}
		let content = ContentBounds;
		// Wrapping: at the text's width (a digit short of the edge), nothing to scroll across.
		if (mWrap)
		{
			let wrap = Math.Max(digit * 8.0f, content.Width - GutterWidth - digit);
			if (wrap != mWrapWidth)
			{
				mWrapWidth = wrap;
				Invalidate();
			}
		}
		let width = mWrap ? content.Width : GutterWidth + Math.Max(mEstimated, mWidest) + digit * 2.0f;
		let height = (float)RowCount * LineHeight + Math.Max(0.0f, content.Height - LineHeight);
		SetScrollExtent(.(width, height));
		// The find bar over the top end corner, still as the code scrolls under it.
		if (mFindBar.Displayed)
		{
			var constraints = LayoutConstraints();
			constraints.Max = .(content.Width, content.Height);
			let size = mFindBar.Measure(constraints);
			let shift = ScrollShift;
			let x = IsRightToLeft ? content.X + 8.0f : content.Right - size.X - 16.0f;
			mFindBar.Arrange(.(x + shift.X, content.Y + 2.0f + shift.Y, size.X, size.Y));
		}
	}

	// Focus going into its find bar scrolls nothing: the bar is always in view.
	public override void OnDescendantFocused(Node focused)
	{
		for (var n = focused; (n != null) && (n != this); n = n.Parent)
		{
			if (n == mFindBar)
				return;
		}
		base.OnDescendantFocused(focused);
	}

	public override void OnScrollChange()
	{
		base.OnScrollChange();
		if (mFindBar.Displayed)
			RequestLayout(); // the bar keeps its place in view
		if (mCompleting)
			PlaceCompletion(); // the list stays at its word
	}

	protected override void OnFocusGained()
	{
		base.OnFocusGained();
		ResetBlink();
		KeepTicking();
	}

	protected override void OnFocusLost()
	{
		base.OnFocusLost();
		mComposition.Clear();
		CloseCompletion();
		Invalidate();
	}

	protected override void OnMouseLeave(MouseEvent e)
	{
		base.OnMouseLeave(e);
		if (mGutterHover)
		{
			mGutterHover = false;
			Invalidate();
		}
	}

	protected override void OnTextInput(TextInputEvent e)
	{
		if (!IsTreeEnabled || mReadOnly || (e.Text.Length == 0))
			return;
		e.Handled = true;
		mComposition.Clear();
		Type(e.Text);
	}

	protected override void OnComposition(CompositionEvent e)
	{
		if (!IsTreeEnabled || mReadOnly)
			return;
		e.Handled = true;
		mComposition.Set(e.Text);
		mCompositionText.SetString(mComposition);
		if (mStyleText != null)
			mStyleText(mCompositionText);
		mCompositionText.SetString(mComposition);
		ResetBlink();
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		if (!IsTreeEnabled || (e.Target != this))
			return;
		let key = (KeyCode)e.KeyCode;
		let mods = e.Modifiers & (KeyModCtrl | KeyModAlt | KeyModSuper | KeyModShift);
		if (mCompleting && (key == .Tab) && (mods == 0))
		{
			AcceptCompletion(); // the list's, as Return (a captured Tab never reaches the keymap)
			e.Handled = true;
			return;
		}
		if ((key == .Escape) && (mods == 0) && (mSelections.Count > 1) && !mCompleting)
		{
			SetOnly(Primary);
			e.Handled = true;
			return;
		}
		if ((key == .Tab) && ((mods == 0) || (mods == KeyModShift)) && !mReadOnly)
		{
			if (mods == KeyModShift)
				IndentLines(true);
			else
				Indent();
			e.Handled = true;
			return;
		}
		// A key that types is its own (it neither activates nor moves focus).
		if (((mods & (KeyModCtrl | KeyModAlt | KeyModSuper)) == 0) && ((key == .Space) || ((key >= .A) && (key <= .Num9))))
			e.Handled = true;
	}

	protected override void OnMouseDown(MouseEvent e)
	{
		if (!IsTreeEnabled || (e.Button != .Left) || FromCompletion(e))
			return;
		e.Handled = true;
		CloseCompletion();
		RequestFocus();
		let local = ConvertToNodeSpace(e.Position);
		let at = PositionAt(local);
		// The marker column: the host's (a breakpoint toggled), the caret staying.
		let content = ContentBounds;
		if ((local.X >= content.X) && (local.X < content.X + cMarkerColumn))
		{
			if (mOnGutterClick != null)
				mOnGutterClick(at.Line);
			return;
		}
		// The fold column: a fold's chevron folds or unfolds it.
		let foldX = content.X + GutterWidth - cTextGap - cFoldColumn;
		if ((local.X >= foldX) && (local.X < foldX + cFoldColumn))
		{
			ToggleFold(at.Line);
			return;
		}
		// A folded line's placeholder unfolds it.
		if (IsFolded(at.Line) && PlaceholderRect(at.Line).Contains(local))
		{
			Unfold(at.Line);
			return;
		}
		mDragUnit = (e.ClickCount >= 3) ? 3u : (e.ClickCount == 2) ? 2u : 1u;
		var unit = CodeRange(at, at);
		if (mDragUnit == 2)
		{
			let word = WordRangeAt(mDoc.LineText(at.Line), (int)at.Column);
			unit = .(.(at.Line, (uint32)word.Start), .(at.Line, (uint32)word.End));
		}
		else if (mDragUnit == 3)
			unit = .(.(at.Line, 0), (at.Line + 1 < mDoc.LineCount) ? CodePosition((uint32)(at.Line + 1), 0) : mDoc.End());
		mDragAdds = (e.Modifiers & KeyModAlt) != 0;
		mDoc.BreakMerge();
		if (((e.Modifiers & KeyModShift) != 0) && (mDragUnit == 1))
		{
			var s = Primary;
			s.Head = at;
			mDragOrigin = .(s.Anchor, s.Anchor);
			SetOnly(s);
		}
		else if (mDragAdds)
		{
			mColumnX = local.X - TextLeft + ScrollShift.X;
			mColumnLine = at.Line;
			mSelections.Add(.(unit.Start, unit.End));
			mPrimary = mSelections.Count - 1;
			Normalize();
			ResetGoals();
			SelectionsChanged();
			mDragOrigin = unit;
		}
		else
		{
			SetOnly(.(unit.Start, unit.End));
			mDragOrigin = unit;
		}
		mDragging = true;
		let dispatcher = EventDispatcher;
		if (dispatcher != null)
			dispatcher.CapturePointer(this);
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		if (FromCompletion(e))
			return;
		if (!mDragging)
		{
			// Hovering: the diagnostics under the pointer, or on its line in the gutter, for the
			// tooltip; over a word, what the service says of it after them.
			let hover = ConvertToNodeSpace(e.Position);
			let over = PositionAt(hover);
			let gutter = hover.X < TextLeft;
			if (gutter != mGutterHover)
			{
				mGutterHover = gutter; // the folds' chevrons show
				Invalidate();
			}
			let tip = scope String();
			if (hover.X < TextLeft)
			{
				for (let d in mDiagnostics)
				{
					if ((mDoc.GetAnchor(d.Start).Line <= over.Line) && (over.Line <= mDoc.GetAnchor(d.End).Line))
					{
						if (!tip.IsEmpty)
							tip.Append("\n");
						tip.Append(d.Message);
					}
				}
			}
			else
			{
				DiagnosticsAt(over, tip);
				// Over the word itself, not the space past a line's end.
				let x = hover.X - TextLeft + ScrollShift.X;
				if ((mService != null) && (over.Line < mDoc.LineCount) && (x <= XOf(mDoc.Clamp(.(over.Line, uint32.MaxValue)))))
				{
					let info = HoverAt(over);
					if (info.Length != 0)
					{
						if (!tip.IsEmpty)
							tip.Append("\n");
						tip.Append(info);
					}
				}
			}
			mHoverTip.Set(tip);
			return;
		}
		let local = ConvertToNodeSpace(e.Position);
		let at = PositionAt(local);
		if (mDragAdds && (mDragUnit == 1) && (at.Line != mColumnLine))
		{
			// Alt+drag across lines: a column, a selection on each line between, at the two places
			// across, in place of the others (VS Code's box selection).
			let x = local.X - TextLeft + ScrollShift.X;
			let next = scope List<CodeSelection>();
			let from = Math.Min(mColumnLine, at.Line);
			let to = Math.Max(mColumnLine, at.Line);
			for (uint32 line = from; line <= to; ++line)
			{
				if (!IsLineHidden(line))
					next.Add(.(.(line, ColumnAtX(line, mColumnX)), .(line, ColumnAtX(line, x))));
			}
			mSelections.Clear();
			mSelections.AddRange(next);
			mPrimary = mSelections.Count - 1;
			Normalize();
			ResetGoals();
			SelectionsChanged();
			return;
		}
		// From what the press selected to what the pointer is on, by the press's unit.
		var unit = CodeRange(at, at);
		if (mDragUnit == 2)
		{
			let word = WordRangeAt(mDoc.LineText(at.Line), (int)at.Column);
			unit = .(.(at.Line, (uint32)word.Start), .(at.Line, (uint32)word.End));
		}
		else if (mDragUnit == 3)
			unit = .(.(at.Line, 0), (at.Line + 1 < mDoc.LineCount) ? CodePosition((uint32)(at.Line + 1), 0) : mDoc.End());
		mSelections[mPrimary] = (at < mDragOrigin.Start) ? CodeSelection(mDragOrigin.End, unit.Start) : CodeSelection(mDragOrigin.Start, unit.End);
		Normalize();
		ResetGoals();
		SelectionsChanged();
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		if (!mDragging || (e.Button != .Left))
			return;
		mDragging = false;
		let dispatcher = EventDispatcher;
		if (dispatcher != null)
			dispatcher.ReleasePointer(this);
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		let content = ContentBounds;
		let shift = ScrollShift;
		let lh = LineHeight;
		let gutter = GutterWidth;
		let textArea = Rect(content.X + gutter, content.Y, Math.Max(0.0f, content.Width - gutter), content.Height);
		Color PartColor(StringView name, Color fallback)
		{
			let part = GetPartStyle(name);
			var color = part.HasBackground ? part.Box.BackgroundColor : fallback;
			color.A *= part.Opacity;
			return color;
		}
		let gutterColor = PartColor("gutter", Color(0.0f, 0.0f, 0.0f, 0.0f));
		Color PartTextColor(StringView name, Color fallback)
		{
			let part = GetPartStyle(name);
			return part.HasColor ? part.TextColor : fallback;
		}
		let numberColor = PartTextColor("line-number", Color(0.5f, 0.53f, 0.6f, 1.0f));
		let currentNumber = PartTextColor("current-line-number", TextColor);
		let currentLine = PartColor("current-line", Color(0.0f, 0.0f, 0.0f, 0.0f)); // the sheet's (none by default)
		let selectionColor = PartColor("selection", Color(0.25f, 0.45f, 0.8f, 0.45f));
		let caretColor = PartColor("caret", TextColor);

		VisibleLines(let first, let last);
		let primary = mDoc.Clamp(Primary.Head);
		float RowTop(uint32 line) => content.Y + (float)RowOfLine(line) * lh - shift.Y;
		let textX = textArea.X - shift.X;

		ctx.PushClip(content);
		// The primary caret's line, across the whole view.
		if (Primary.IsEmpty && (primary.Line >= first) && (primary.Line <= last) && (currentLine.A > 0.0f))
			ctx.VG.FillRect(.(content.X, RowTop(primary.Line), content.Width, lh * (float)RowsOf(primary.Line)), currentLine);
		// The line the debugger stands on, across the view.
		for (let marker in mMarkers)
		{
			if (marker.Kind == "execution")
			{
				let line = mDoc.GetAnchor(marker.Anchor).Line;
				if ((line >= first) && (line <= last) && !IsLineHidden(line))
					ctx.VG.FillRect(.(content.X, RowTop(line), content.Width, lh * (float)RowsOf(line)),
						PartColor("execution-line", Color(0.9f, 0.75f, 0.2f, 0.15f)));
			}
		}
		ctx.PushClip(textArea);
		// The find bar's matches in view, the current one stronger.
		if (mFindBar.Displayed && (mFindBar.GetMode() != .GoToLine))
		{
			RefreshMatches();
			let matchColor = PartColor("find-match", Color(0.85f, 0.65f, 0.2f, 0.3f));
			let currentColor = PartColor("find-current", Color(0.95f, 0.7f, 0.2f, 0.6f));
			let current = Primary.Range;
			for (let r in mMatches)
			{
				if (r.End.Line < first)
					continue;
				if (r.Start.Line > last)
					break;
				for (uint32 line = Math.Max(r.Start.Line, first); line <= Math.Min(r.End.Line, last); ++line)
				{
					if (IsLineHidden(line))
						continue;
					let fill = (r == current) ? currentColor : matchColor;
					ForEachRun(line, (line == r.Start.Line) ? r.Start.Column : 0, (line == r.End.Line) ? r.End.Column : LineEnd(line), false,
						scope (x0, x1, row) =>
						{
							ctx.VG.FillRect(.(textX + x0, content.Y + (float)row * lh - shift.Y, Math.Max(1.0f, x1 - x0), lh), fill);
						});
				}
			}
		}
		// The selections, then the text over them.
		for (let s in mSelections)
		{
			if (s.IsEmpty)
				continue;
			let r = s.Range;
			for (uint32 line = Math.Max(r.Start.Line, first); line <= Math.Min(r.End.Line, last); ++line)
			{
				if (IsLineHidden(line))
					continue;
				ForEachRun(line, (line == r.Start.Line) ? r.Start.Column : 0, (line == r.End.Line) ? r.End.Column : LineEnd(line), line != r.End.Line,
					scope (x0, x1, row) =>
					{
						ctx.VG.FillRect(.(textX + x0, content.Y + (float)row * lh - shift.Y, Math.Max(0.0f, x1 - x0), lh), selectionColor);
					});
			}
		}
		// The bracket by the primary caret and its match, marked.
		if (Primary.IsEmpty && FindMatchingBracket(primary, let bracket, let match))
		{
			let mark = PartColor("bracket-match", Color(0.5f, 0.6f, 0.75f, 0.35f));
			CodeRange[2] both = .(bracket, match);
			for (let r in both)
			{
				if ((r.Start.Line >= first) && (r.Start.Line <= last) && !IsLineHidden(r.Start.Line))
				{
					ForEachRun(r.Start.Line, r.Start.Column, r.End.Column, false, scope (x0, x1, row) =>
						{
							ctx.VG.FillRect(.(textX + x0, content.Y + (float)row * lh - shift.Y, x1 - x0, lh), mark);
						});
				}
			}
		}
		for (uint32 line = first; line <= last; ++line)
		{
			if (IsLineHidden(line))
				continue;
			let view = View(line);
			let layout = LayoutOf(view);
			if (mWhitespace != .None)
				DrawWhitespace(ctx, line, view, layout, textX, RowTop(line), PartTextColor("whitespace", numberColor));
			// Its rows from its first (each a line height: the layout's own, the same font's).
			let lead = layout.Lines.IsEmpty ? 0.0f : (lh - layout.Lines[0].Height) * 0.5f;
			view.Glyphs.DrawLayout(ctx, layout, .(textX, RowTop(line) + lead));
			// A folded line's placeholder after its text.
			if (IsFolded(line))
			{
				let @box = PlaceholderRect(line);
				ctx.VG.FillRoundedRect(.(@box.X, @box.Y, @box.Width, @box.Height), 3.0f,
					PartColor("fold-placeholder", Color(0.5f, 0.55f, 0.65f, 0.25f)));
				mFoldText.Color = numberColor;
				let dots = mFoldText.LayoutFor(.());
				mFoldText.DrawLayout(ctx, dots, .(@box.X + (@box.Width - dots.Width) * 0.5f, @box.Y + (@box.Height - dots.Height) * 0.5f));
			}
		}
		// The diagnostics: a wave under each run, the worse over the lesser.
		for (uint32 pass = 0; pass < 4; ++pass)
		{
			for (let d in mDiagnostics)
			{
				if ((uint32)d.Severity != pass)
					continue;
				let r = MarkedRange(d);
				if ((r.End.Line < first) || (r.Start.Line > last))
					continue;
				let color = PartColor(CodeSeverityName(d.Severity), (d.Severity == .Error) ? Color(0.95f, 0.33f, 0.4f, 1.0f)
					: Color(0.95f, 0.8f, 0.4f, 1.0f));
				for (uint32 line = Math.Max(r.Start.Line, first); line <= Math.Min(r.End.Line, last); ++line)
				{
					if (IsLineHidden(line))
						continue;
					ForEachRun(line, (line == r.Start.Line) ? r.Start.Column : 0, (line == r.End.Line) ? r.End.Column : LineEnd(line), false,
						scope (left, right, row) =>
						{
							let x0 = textX + left;
							let x1 = textX + right;
							let y = content.Y + (float)row * lh - shift.Y + lh - 2.0f;
							let wave = scope PathBuilder();
							wave.MoveTo(x0, y);
							bool up = true;
							var x = x0 + 2.0f;
							while (x <= Math.Max(x1, x0 + 4.0f))
							{
								wave.LineTo(x, up ? y - 1.5f : y);
								x += 2.0f;
								up = !up;
							}
							let path = wave.ToPath();
							ctx.VG.StrokePath(path, color, StrokeStyle(1.0f, .Round, .Round));
							delete path;
						});
				}
			}
		}
		// An IME's composition at the primary caret, underlined.
		if (!mComposition.IsEmpty && IsFocused)
		{
			let caret = CaretRect(primary);
			let width = ComposedWidth();
			ctx.VG.FillRect(.(caret.X, caret.Y, width, lh), PartColor("composition", Color(0.15f, 0.17f, 0.22f, 1.0f)));
			mCompositionText.DrawLayout(ctx, mCompositionText.LayoutFor(.()), .(caret.X, caret.Y));
			ctx.VG.FillRect(.(caret.X, caret.Y + lh - 1.5f, width, 1.0f), TextColor);
		}
		// The carets.
		if (IsFocused && mCaretShown)
		{
			for (let s in mSelections)
			{
				let at = mDoc.Clamp(s.Head);
				if ((at.Line < first) || (at.Line > last) || IsLineHidden(at.Line))
					continue;
				let place = PlaceOf(at);
				ctx.VG.FillRect(.(textX + place.X + ((at == primary) ? ComposedWidth() : 0.0f), content.Y + (float)place.Row * lh - shift.Y, 1.5f, lh), caretColor);
			}
		}
		ctx.PopClip();
		// The gutter: still across, the numbers right aligned.
		if (gutterColor.A > 0.0f)
			ctx.VG.FillRect(.(content.X, content.Y, gutter, content.Height), gutterColor);
		// The marker column: a line's worst diagnostic, then its marks over it (an execution arrow
		// last).
		for (uint32 line = first; line <= last; ++line)
		{
			if (IsLineHidden(line))
				continue;
			let cx = content.X + cMarkerColumn * 0.5f;
			let cy = RowTop(line) + lh * 0.5f;
			let radius = Math.Min(lh, cMarkerColumn) * 0.28f;
			if (WorstOn(line, let worst) && (worst >= .Info))
				ctx.VG.FillCircle(.(cx, cy), radius * 0.75f, PartColor(CodeSeverityName(worst), Color(0.95f, 0.33f, 0.4f, 1.0f)));
			for (int layer = 0; layer < 2; ++layer)
			{
				for (let marker in mMarkers)
				{
					if (mDoc.GetAnchor(marker.Anchor).Line != line)
						continue;
					StringView kind = marker.Kind;
					let execution = kind == "execution";
					if (execution != (layer == 1))
						continue;
					if (kind == "breakpoint")
						ctx.VG.FillCircle(.(cx, cy), radius, PartColor("breakpoint", Color(0.9f, 0.33f, 0.3f, 1.0f)));
					else if (execution)
					{
						let arrow = scope PathBuilder();
						arrow.MoveTo(cx - radius, cy - radius);
						arrow.LineTo(cx + radius, cy);
						arrow.LineTo(cx - radius, cy + radius);
						arrow.Close();
						let path = arrow.ToPath();
						ctx.VG.FillPath(path, PartColor("execution", Color(0.95f, 0.8f, 0.3f, 1.0f)));
						delete path;
					}
					else if (kind == "bookmark")
						ctx.VG.FillRect(.(cx - radius * 0.6f, cy - radius, radius * 1.2f, radius * 2.0f), PartColor("bookmark", Color(0.5f, 0.67f, 1.0f, 1.0f)));
					else
						ctx.VG.FillRect(.(cx - radius * 0.7f, cy - radius * 0.7f, radius * 1.4f, radius * 1.4f), PartColor("marker", Color(0.6f, 0.65f, 0.75f, 1.0f)));
				}
			}
		}
		// The fold column: a folded range's chevron always, an open one's while the pointer is over
		// the gutter (VS Code's), worked out only then.
		let chevrons = mGutterHover || !mFolded.IsEmpty;
		let foldColor = PartTextColor("fold", numberColor);
		for (uint32 line = first; (line <= last) && chevrons; ++line)
		{
			if (IsLineHidden(line) || (RangeStarting(line) == null))
				continue;
			let folded = IsFolded(line);
			if (!folded && !mGutterHover)
				continue;
			let cx = content.X + gutter - cTextGap - cFoldColumn * 0.5f;
			let cy = RowTop(line) + lh * 0.5f;
			let r = Math.Min(lh, cFoldColumn) * 0.2f;
			let chevron = scope PathBuilder();
			if (folded)
			{
				chevron.MoveTo(cx - r * 0.5f, cy - r);
				chevron.LineTo(cx + r * 0.5f, cy);
				chevron.LineTo(cx - r * 0.5f, cy + r);
			}
			else
			{
				chevron.MoveTo(cx - r, cy - r * 0.5f);
				chevron.LineTo(cx, cy + r * 0.5f);
				chevron.LineTo(cx + r, cy - r * 0.5f);
			}
			let path = chevron.ToPath();
			ctx.VG.StrokePath(path, foldColor, StrokeStyle(1.25f, .Round, .Round));
			delete path;
		}
		for (uint32 line = first; line <= last; ++line)
		{
			if (IsLineHidden(line))
				continue;
			let view = View(line);
			if (view.NumberOf != line)
			{
				view.NumberOf = line;
				if (mStyleText != null)
					mStyleText(view.Number);
				view.Number.SetString(scope String()..AppendF("{}", line + 1));
			}
			view.Number.Color = (line == primary.Line) ? currentNumber : numberColor;
			let layout = view.Number.LayoutFor(.());
			view.Number.DrawLayout(ctx, layout, .(content.X + gutter - cTextGap - cFoldColumn - cGutterPad - layout.Width, RowTop(line) + (lh - layout.Height) * 0.5f));
		}
		ctx.PopClip();
	}

	// === The document's changes ===

	private void Attach(CodeDocument document)
	{
		mDoc = document;
		ClearAndDeleteItems!(mViews);
		mFoldRangesVersion = uint64.MaxValue;
		mRowsVersion = uint64.MaxValue;
		mWidestVersion = uint64.MaxValue;
		mWidest = 0.0f;
		mListener = mDoc.AddChangeListener(new (change) => { DocumentChanged(change); });
	}

	private void Detach()
	{
		if (mDoc == null)
			return;
		mDoc.RemoveChangeListener(mListener);
		ClearDiagnosticAnchors(); // its marks are the document's places: they go with it
		for (let marker in mMarkers)
			mDoc.RemoveAnchor(marker.Anchor);
		ClearAndDeleteItems!(mMarkers);
		for (let anchor in mFolded)
			mDoc.RemoveAnchor(anchor);
		mFolded.Clear();
	}

	private void DocumentChanged(CodeChange change)
	{
		// The tokens of the lines below move with them; the changed lines' go; what follows a change
		// is checked again from there (its state may differ now).
		let lexFirst = Math.Min((int)change.FirstLine, mLex.Count);
		let lexRemoved = Math.Min((int)change.RemovedLines, mLex.Count - lexFirst);
		for (int i < lexRemoved)
		{
			delete mLex[lexFirst];
			mLex.RemoveAt(lexFirst);
		}
		for (uint32 i = 0; (i < change.InsertedLines) && (lexFirst <= mLex.Count); ++i)
			mLex.Insert(lexFirst, new LineLex());
		mCleanTo = Math.Min(mCleanTo, change.FirstLine);
		// The host's fold ranges go with their lines.
		for (int i = mHostRanges.Count - 1; i >= 0; i--)
		{
			var r = mHostRanges[i];
			r.First = CodeDocument.Moved(.(r.First, 0), .Right, change.Replaced, change.End).Line;
			r.Last = CodeDocument.Moved(.(r.Last, 0), .Right, change.Replaced, change.End).Line;
			if (r.Last <= r.First)
				mHostRanges.RemoveAt(i);
			else
				mHostRanges[i] = r;
		}
		// Its selections go through the edit (one another view made; its own edits set them after).
		for (int i < mSelections.Count)
		{
			let sel = mSelections[i];
			mSelections[i] = .(CodeDocument.Moved(sel.Anchor, .Right, change.Replaced, change.End),
				CodeDocument.Moved(sel.Head, .Right, change.Replaced, change.End));
		}
		// The views below the change move with their lines; the changed ones go.
		let first = Math.Min((int)change.FirstLine, mViews.Count);
		let removed = Math.Min((int)change.RemovedLines, mViews.Count - first);
		for (int i < removed)
		{
			delete mViews[first];
			mViews.RemoveAt(first);
		}
		for (uint32 i = 0; (i < change.InsertedLines) && (first <= mViews.Count); ++i)
			mViews.Insert(first, (LineView)null);
		RequestLayout();
		Invalidate();
	}

	// === Lines laid out ===

	// A line's view, laid out (made, or remade when its text changed).
	private LineView View(uint32 line)
	{
		while (mViews.Count < (int)mDoc.LineCount)
			mViews.Add(null);
		var view = mViews[(int)line];
		if (view == null)
		{
			view = new LineView();
			mViews[(int)line] = view;
		}
		let hash = mDoc.LineHash(line);
		uint64 stamp = 0;
		if (mLanguage != null)
		{
			EnsureLexed(line);
			stamp = mLex[(int)line].Stamp;
		}
		if (view.Laid && (view.Hash == hash) && (view.TabSize == mTabSize) && (view.LexStamp == stamp))
			return view;
		view.LexStamp = stamp;
		view.Laid = true;
		view.Hash = hash;
		view.TabSize = mTabSize;
		view.Shown.Clear();
		view.ShownAt.Clear();
		let text = mDoc.LineText(line);
		bool tabs = false;
		for (int i = 0; (i < text.Length) && !tabs; ++i)
			tabs = text[i] == '\t';
		let cut = Math.Min(text.Length, (int)cLongestLaidOut);
		if (!tabs)
			view.Shown.Set(text.Substring(0, cut));
		else
		{
			uint32 visual = 0; // characters before, for the tab stops
			for (int i < cut)
			{
				view.ShownAt.Add((uint32)view.Shown.Length);
				let c = text[i];
				if (c == '\t')
				{
					let spaces = (uint32)(mTabSize - visual % mTabSize);
					for (uint32 k < spaces)
						view.Shown.Append(" ");
					visual += spaces;
					continue;
				}
				view.Shown.Append(c);
				if (((uint8)c & 0xC0) != 0x80)
					++visual;
			}
			for (int i = cut; i <= text.Length; ++i)
				view.ShownAt.Add((uint32)view.Shown.Length);
		}
		if (mStyleText != null)
			mStyleText(view.Glyphs);
		if (mWrap)
		{
			view.Glyphs.WhiteSpace = .PreWrap;
			view.Glyphs.BreakWords = true;
		}
		if (mLanguage == null)
			view.Glyphs.SetString(view.Shown);
		else
		{
			// Its tokens as the core's rich text: each run in its token's colour ("[[" a "[").
			let markup = scope String();
			StringView shown = view.Shown;
			uint32 done = 0;
			for (let span in mLex[(int)line].Spans)
			{
				let from = ShownColumn(view, span.Start);
				let to = ShownColumn(view, span.End);
				if ((int)from >= shown.Length)
					break;
				if (from > done)
					AppendEscaped(markup, shown.Substring((int)done, (int)(from - done)));
				let part = shown.Substring((int)from, Math.Min((int)to, shown.Length) - (int)from);
				if (span.Token == .Text)
					AppendEscaped(markup, part);
				else
				{
					let c = TokenColor(span.Token);
					const String cHex = "0123456789abcdef";
					float[4] channels = .(c.R, c.G, c.B, c.A);
					markup.Append("[color=#");
					for (int k < 4)
					{
						let v = (uint32)(Math.Clamp(channels[k], 0.0f, 1.0f) * 255.0f + 0.5f);
						markup.Append(cHex[(int)(v >> 4)]);
						markup.Append(cHex[(int)(v & 15)]);
					}
					markup.Append("]");
					AppendEscaped(markup, part);
					markup.Append("[/color]");
				}
				done = Math.Min(to, (uint32)shown.Length);
			}
			if ((int)done < shown.Length)
				AppendEscaped(markup, shown.Substring((int)done, shown.Length - (int)done));
			view.Glyphs.SetMarkup(markup);
		}
		mWidest = Math.Max(mWidest, view.Glyphs.LayoutFor(.()).Width);
		return view;
	}

	// `part` as rich text's plain text ("[[" a "["), appended to `markup`.
	private static void AppendEscaped(String markup, StringView part)
	{
		for (int i < part.Length)
		{
			if (part[i] == '[')
				markup.Append("[[");
			else
				markup.Append(part[i]);
		}
	}

	private float DigitWidth()
	{
		let width = mMeasure.LayoutFor(.()).Width / 10.0f;
		return (width > 0.0f) ? width : 8.0f;
	}

	private static uint32 ShownColumn(LineView view, uint32 column)
	{
		if (view.ShownAt.IsEmpty)
			return Math.Min(column, (uint32)view.Shown.Length);
		return view.ShownAt[Math.Min((int)column, view.ShownAt.Count - 1)];
	}

	private static uint32 ByteColumn(LineView view, uint32 shown)
	{
		if (view.ShownAt.IsEmpty)
			return shown;
		// The column whose place is nearest (inside a tab's spaces: the nearer side).
		uint32 column = 0;
		while (((int)column + 1 < view.ShownAt.Count) && (view.ShownAt[(int)column + 1] <= shown))
			++column;
		if (((int)column + 1 < view.ShownAt.Count) && (shown - view.ShownAt[(int)column] > view.ShownAt[(int)column + 1] - shown))
			++column;
		return column;
	}

	// A line laid out: at the wrap width while wrapping, else unbounded.
	private TextLayout LayoutOf(LineView view)
	{
		return view.Glyphs.LayoutFor(.(0.0f, 0.0f, mWrap ? mWrapWidth : 0.0f, 0.0f));
	}

	// How many rows a line shown takes: one, or its wrapped lines.
	private uint32 RowsOf(uint32 line)
	{
		if (!mWrap)
			return 1;
		return Math.Max((uint32)1, (uint32)LayoutOf(View(line)).Lines.Count);
	}

	private Place PlaceOf(CodePosition at)
	{
		let view = View(at.Line);
		let layout = LayoutOf(view);
		let shown = ShownColumn(view, at.Column);
		if (layout.Lines.IsEmpty)
			return .(0.0f, RowOfLine(at.Line));
		let sub = layout.LineOf((int)shown);
		let x = layout.CaretXOnLine((int)shown, sub);
		return .(x, RowOfLine(at.Line) + (IsLineHidden(at.Line) ? 0u : (uint32)sub));
	}

	private float XOf(CodePosition at) => PlaceOf(at).X;

	// The column nearest `x` across on row `sub` of `line`.
	private uint32 ColumnAt(uint32 line, uint32 sub, float x)
	{
		let view = View(line);
		let layout = LayoutOf(view);
		if (layout.Lines.IsEmpty)
			return 0;
		let shown = layout.OffsetOnLine(Math.Min((int)sub, layout.Lines.Count - 1), x);
		return mDoc.Clamp(.(line, ByteColumn(view, (uint32)shown))).Column;
	}

	private uint32 ColumnAtX(uint32 line, float x) => ColumnAt(line, 0, x);

	// Each row a run of `line` covers, from byte column `from` to `to`: across from x0 to x1, on its
	// row. A run going on past a row's end to the next fills to the row's end; `toEnd` (a selection
	// going on to the next line) carries the last on a little past the text.
	private void ForEachRun(uint32 line, uint32 from, uint32 to, bool toEnd, delegate void(float x0, float x1, uint32 row) fn)
	{
		let view = View(line);
		let layout = LayoutOf(view);
		let a = (int)ShownColumn(view, from);
		let b = (int)ShownColumn(view, to);
		let row = RowOfLine(line);
		if (layout.Lines.IsEmpty)
		{
			fn(0.0f, toEnd ? DigitWidth() * 0.5f : 0.0f, row);
			return;
		}
		for (int i < layout.Lines.Count)
		{
			let l = layout.Lines[i];
			let last = i + 1 == layout.Lines.Count;
			if ((b < l.Start) || (a > l.End))
				continue; // wholly on another row
			if (!last && (a == l.End) && (b > a) && (layout.Lines[i + 1].Start == l.End))
				continue; // starts where a word broke: on the next row
			if ((i > 0) && (b == l.Start) && (a < l.Start) && !(last && toEnd))
				continue; // ends where this row starts
			let s = Math.Max(a, l.Start);
			let e = Math.Min(b, l.End);
			let x0 = layout.CaretXOnLine(s, i);
			var x1 = layout.CaretXOnLine(Math.Max(s, e), i);
			if ((b > l.End) && !last)
				x1 = Math.Max(x1, l.Left + l.Width); // on to the next row
			if (last && toEnd)
				x1 += DigitWidth() * 0.5f;
			fn(x0, x1, row + (uint32)i);
		}
	}

	private float ComposedWidth()
	{
		return mComposition.IsEmpty ? 0.0f : mCompositionText.LayoutFor(.()).Width;
	}

	private uint32 LineEnd(uint32 line) => (uint32)mDoc.LineText(line).Length;

	// === Selections ===

	private void SetOnly(CodeSelection selection)
	{
		var selection;
		SetSelections(.(&selection, 1));
	}

	// Sorted by start; those that overlap (or start at one place: two carets) as one, the primary kept.
	private void Normalize()
	{
		let primary = mSelections[mPrimary];
		for (int i = 1; i < mSelections.Count; ++i) // insertion sort: few, and nearly sorted
		{
			for (int j = i; (j > 0) && (mSelections[j].Range.Start < mSelections[j - 1].Range.Start); --j)
				Swap!(mSelections[j], mSelections[j - 1]);
		}
		let merged = scope List<CodeSelection>();
		for (let s in mSelections)
		{
			if (!merged.IsEmpty)
			{
				let a = merged.Back.Range;
				let b = s.Range;
				if ((b.Start < a.End) || (b.Start == a.Start)) // overlapping, or starting at one place
				{
					let end = (a.End < b.End) ? b.End : a.End;
					let forward = !(s.Head < s.Anchor);
					merged[merged.Count - 1] = forward ? CodeSelection(a.Start, end) : CodeSelection(end, a.Start);
					continue;
				}
			}
			merged.Add(s);
		}
		mSelections.Clear();
		mSelections.AddRange(merged);
		mPrimary = 0;
		for (int i < mSelections.Count)
		{
			let r = mSelections[i].Range;
			if ((r.Start <= primary.Head) && (primary.Head <= r.End))
				mPrimary = i;
		}
	}

	private void ResetGoals()
	{
		mGoals.Clear();
		for (int i < mSelections.Count)
			mGoals.Add(-1.0f);
	}

	private void SelectionsChanged()
	{
		RevealCarets();
		ResetBlink();
		ScrollToCaret();
		Invalidate();
		if (mCompleting)
			UpdateCompletion();
	}

	// === Folding ===

	// The fold ranges, computed again when the text changed.
	private void EnsureFoldRanges()
	{
		if (mFoldRangesVersion == mDoc.Version)
			return;
		mFoldRangesVersion = mDoc.Version;
		mFoldRanges.Clear();
		let count = mDoc.LineCount;
		if (mHostFolds)
		{
			for (let r in mHostRanges)
			{
				if ((r.First < r.Last) && (r.Last < count))
					mFoldRanges.Add(r);
			}
		}
		else if ((mLanguage != null) && !mLanguage.FoldByIndent && !mLanguage.Brackets.IsEmpty)
			BracketFolds();
		else
			IndentFolds();
		if ((mLanguage != null) && !mLanguage.RegionStart.IsEmpty && !mLanguage.RegionEnd.IsEmpty)
		{
			// A region from its start's line through its end's.
			let open = scope List<uint32>();
			for (uint32 line = 0; line < count; ++line)
			{
				let text = mDoc.LineText(line);
				let trimmed = text.Substring((int)IndentOf(text), text.Length - (int)IndentOf(text));
				if (trimmed.StartsWith(mLanguage.RegionStart))
					open.Add(line);
				else if (trimmed.StartsWith(mLanguage.RegionEnd) && !open.IsEmpty)
				{
					if (line > open.Back)
						mFoldRanges.Add(.(open.Back, line));
					open.PopBack();
				}
			}
		}
		// By first line, the widest of those starting on one line (stable, as the order found).
		for (int i = 1; i < mFoldRanges.Count; i++)
		{
			let key = mFoldRanges[i];
			int j = i;
			while ((j > 0) && ((key.First != mFoldRanges[j - 1].First) ? (key.First < mFoldRanges[j - 1].First) : (key.Last > mFoldRanges[j - 1].Last)))
			{
				mFoldRanges[j] = mFoldRanges[j - 1];
				--j;
			}
			mFoldRanges[j] = key;
		}
		for (int i = mFoldRanges.Count - 1; i >= 1; i--)
		{
			if (mFoldRanges[i].First == mFoldRanges[i - 1].First)
				mFoldRanges.RemoveAt(i);
		}
	}

	// From each bracket's line to the line before its close's (its close's own when something comes
	// before it there), past strings and comments.
	private void BracketFolds()
	{
		let count = mDoc.LineCount;
		EnsureLexed((uint32)(count - 1));
		let stack = scope List<OpenBracket>();
		for (uint32 line = 0; line < count; ++line)
		{
			let text = mDoc.LineText(line);
			let indent = IndentOf(text);
			for (let span in mLex[(int)line].Spans)
			{
				if ((span.Token == .String) || (span.Token == .Comment) || (span.Token == .Escape))
					continue;
				for (uint32 i = span.Start; (i < span.End) && ((int)i < text.Length); ++i)
				{
					for (let pair in mLanguage.Brackets)
					{
						if ((pair.Open.Length != 1) || (pair.Close.Length != 1))
							continue;
						if (text[(int)i] == pair.Open[0])
							stack.Add(.(pair.Close[0], line));
						else if (text[(int)i] == pair.Close[0])
						{
							while (!stack.IsEmpty && (stack.Back.Close != text[(int)i]))
								stack.PopBack(); // an unclosed one inside: dropped
							if (stack.IsEmpty)
								break;
							let first = stack.Back.Line;
							stack.PopBack();
							let last = (i == indent) ? (uint32)(line - ((line > 0) ? 1u : 0u)) : line;
							if (last > first)
								mFoldRanges.Add(.(first, last));
						}
					}
				}
			}
		}
	}

	// From a line to the last after it indented further (blank lines between kept, those after the
	// last left out).
	private void IndentFolds()
	{
		let stack = scope List<OpenIndent>();
		let count = mDoc.LineCount;
		uint32 lastText = 0;
		// The open lines indented `indent` or more, each to the last line with text (`last`).
		void CloseOpen(uint32 indent, uint32 last)
		{
			while (!stack.IsEmpty && (stack.Back.Indent >= indent))
			{
				if (last > stack.Back.Line)
					mFoldRanges.Add(.(stack.Back.Line, last));
				stack.PopBack();
			}
		}
		for (uint32 line = 0; line < count; ++line)
		{
			let text = mDoc.LineText(line);
			let bytes = IndentOf(text);
			if (bytes == (uint32)text.Length)
				continue; // blank
			let indent = IndentColumns(text.Substring(0, (int)bytes));
			CloseOpen(indent, lastText);
			stack.Add(.(indent, line));
			lastText = line;
		}
		CloseOpen(0, lastText);
	}

	// Each line's first row, a line in a folded range none (its next line's); the total last.
	private void EnsureRows()
	{
		let wrap = mWrap ? mWrapWidth : 0.0f;
		if ((mRowsVersion == mDoc.Version) && (mRowsStamp == mFoldStamp) && (mRowsWrap == wrap) && (mRowsTabSize == mTabSize))
			return;
		mRowsVersion = mDoc.Version;
		mRowsStamp = mFoldStamp;
		mRowsWrap = wrap;
		mRowsTabSize = mTabSize;
		let count = mDoc.LineCount;
		mRowStart.Clear();
		let folded = scope List<CodeFoldRange>();
		if (!mFolded.IsEmpty)
		{
			EnsureFoldRanges();
			// A fold whose range is gone (its bracket deleted) is forgotten.
			for (int i = mFolded.Count - 1; i >= 0; i--)
			{
				let r = RangeStarting(mDoc.GetAnchor(mFolded[i]).Line);
				if (r == null)
				{
					mDoc.RemoveAnchor(mFolded[i]);
					mFolded.RemoveAt(i);
				}
				else
					folded.Add(r.Value);
			}
			for (int i = 1; i < folded.Count; i++) // stable, by first line
			{
				let key = folded[i];
				int j = i;
				while ((j > 0) && (key.First < folded[j - 1].First))
				{
					folded[j] = folded[j - 1];
					--j;
				}
				folded[j] = key;
			}
		}
		uint32 row = 0;
		int64 hiddenTo = -1;
		int next = 0;
		for (uint32 line = 0; line < count; ++line)
		{
			mRowStart.Add(row);
			if ((int64)line <= hiddenTo)
				continue;
			row += RowsOf(line);
			for (; (next < folded.Count) && (folded[next].First <= line); ++next)
			{
				if (folded[next].First == line)
					hiddenTo = Math.Max(hiddenTo, (int64)folded[next].Last);
			}
		}
		mRowStart.Add(row);
	}

	private CodeFoldRange? RangeStarting(uint32 line)
	{
		EnsureFoldRanges();
		for (let r in mFoldRanges)
		{
			if (r.First == line)
				return r;
		}
		return null;
	}

	// A line's first row; a hidden line's, its fold's.
	private uint32 RowOfLine(uint32 line)
	{
		EnsureRows();
		let clamped = (int)Math.Min(line, (uint32)(mDoc.LineCount - 1));
		let row = mRowStart[clamped];
		if ((mRowStart[clamped + 1] != row) || (row == 0))
			return row;
		var shown = clamped; // hidden: its fold's first row (the line it folds onto may wrap)
		while ((shown > 0) && (mRowStart[shown + 1] == mRowStart[shown]))
			--shown;
		return mRowStart[shown];
	}

	// The line shown on `row` (the last line starting at or before it: a hidden one starts where the
	// line after its fold does, so this is that line).
	private uint32 LineOfRow(uint32 row, uint32* sub = null)
	{
		EnsureRows();
		int low = 0;
		int high = (int)mDoc.LineCount; // the first line starting after the row
		while (low < high)
		{
			let mid = (low + high) / 2;
			if (mRowStart[mid] <= row)
				low = mid + 1;
			else
				high = mid;
		}
		var line = (low == 0) ? 0 : low - 1;
		while ((line > 0) && (mRowStart[line + 1] == mRowStart[line]))
			--line; // past the end, in a fold: its first line
		if (sub != null)
			*sub = (row >= mRowStart[line]) ? Math.Min((uint32)(row - mRowStart[line]), (uint32)(mRowStart[line + 1] - mRowStart[line] - 1)) : 0;
		return (uint32)line;
	}

	private void FoldsChanged()
	{
		++mFoldStamp;
		RequestLayout();
		Invalidate();
	}

	// A line's whitespace as the choice says: a dot mid-space, an arrow across a tab.
	private void DrawWhitespace(DrawContext ctx, uint32 line, LineView view, TextLayout layout, float textX, float top, Color color)
	{
		if (layout.Lines.IsEmpty)
			return;
		let text = mDoc.LineText(line);
		let lh = LineHeight;
		let upTo = Math.Min(text.Length, (int)cLongestLaidOut);
		for (uint32 column = 0; (int)column < upTo; ++column)
		{
			if (((text[(int)column] != ' ') && (text[(int)column] != '\t')) || !ShowsWhitespaceAt(.(line, column)))
				continue;
			let from = (int)ShownColumn(view, column);
			let to = (int)ShownColumn(view, column + 1);
			let sub = layout.LineOf(from);
			let x0 = textX + layout.CaretXOnLine(from, sub);
			let x1 = textX + layout.CaretXOnLine(to, sub);
			let y = top + (float)sub * lh + lh * 0.5f;
			if (text[(int)column] == ' ')
				ctx.VG.FillCircle(.((x0 + x1) * 0.5f, y), Math.Max(1.0f, lh * 0.07f), color);
			else
			{
				let head = Math.Min(lh * 0.2f, (x1 - x0) * 0.4f);
				let arrow = scope PathBuilder();
				arrow.MoveTo(x0 + 2.0f, y);
				arrow.LineTo(x1 - 2.0f, y);
				arrow.MoveTo(x1 - 2.0f - head, y - head);
				arrow.LineTo(x1 - 2.0f, y);
				arrow.LineTo(x1 - 2.0f - head, y + head);
				let path = arrow.ToPath();
				ctx.VG.StrokePath(path, color, StrokeStyle(1.0f, .Round, .Round));
				delete path;
			}
		}
	}

	// A folded line's placeholder, after its text (local space).
	private Rect PlaceholderRect(uint32 line)
	{
		let end = CaretRect(.(line, (uint32)mDoc.LineText(line).Length));
		let width = mFoldText.LayoutFor(.()).Width + 8.0f;
		return .(end.X + DigitWidth() * 0.5f, end.Y + 1.0f, width, end.Height - 2.0f);
	}

	// Folds `range` (not folded yet), its carets out to the line it stays on.
	private void FoldRange(CodeFoldRange range)
	{
		mFolded.Add(mDoc.AddAnchor(.(range.First, 0), .Right));
		FoldsChanged();
		CaretsOutOfFolds();
	}

	// Each caret in a folded range to the end of the line its fold stays on.
	private void CaretsOutOfFolds()
	{
		bool moved = false;
		for (int i < mSelections.Count)
		{
			if (IsLineHidden(mSelections[i].Head.Line))
			{
				let line = LineOfRow(RowOfLine(mSelections[i].Head.Line));
				let end = CodePosition(line, (uint32)mDoc.LineText(line).Length);
				mSelections[i] = .(end, end);
				moved = true;
			}
		}
		if (!moved)
			return;
		Normalize();
		ResetGoals();
		SelectionsChanged();
	}

	// A caret in a folded range unfolds it (a match found, a line gone to, a step into it).
	private void RevealCarets()
	{
		if (mFolded.IsEmpty)
			return;
		for (let sel in mSelections)
		{
			while (IsLineHidden(sel.Head.Line) && Unfold(sel.Head.Line))
			{
			}
		}
	}

	// === Completion ===

	// An event from the open list, on its way up through its owner.
	private bool FromCompletion(Event e)
	{
		for (var n = e.Target; (n != null) && (n != this); n = n.Parent)
		{
			if (n == mCompletion)
				return true;
		}
		return false;
	}

	private bool IsWordByte(char8 c) => IsNameByte(c) || ((c == '-') && (mLanguage != null) && mLanguage.IdentifierDashes);

	// Where the word ending at `at` begins (at itself when none does).
	private CodePosition WordStartBefore(CodePosition at)
	{
		let text = mDoc.LineText(at.Line);
		var column = Math.Min(at.Column, (uint32)text.Length);
		while ((column > 0) && IsWordByte(text[(int)column - 1]))
			--column;
		return .(at.Line, column);
	}

	// The word typed since the list opened; false when the caret has left it.
	private bool TypedWord(out StringView word)
	{
		word = default;
		let primary = Primary;
		if (!primary.IsEmpty || (primary.Head.Line != mWordStart.Line) || (primary.Head.Column < mWordStart.Column))
			return false;
		let text = mDoc.LineText(primary.Head.Line);
		if ((int)primary.Head.Column > text.Length)
			return false;
		word = text.Substring((int)mWordStart.Column, (int)primary.Head.Column - (int)mWordStart.Column);
		if ((word.Length == 0) && !mCompletedEmpty)
			return false; // back to the start of a word it opened on
		for (int i < word.Length)
		{
			if (!IsWordByte(word[i]))
				return false;
		}
		return true;
	}

	// The caret moved or the text changed under the open list: filtered again by the word, else
	// closed when the caret left it or nothing matches.
	private void UpdateCompletion()
	{
		if (!TypedWord(let word) || (mCompletion.Filter(word) == 0))
		{
			CloseCompletion();
			return;
		}
		PlaceCompletion();
	}

	// The word's start, in the root's space, its label lined up with the word.
	private Rect CompletionAnchor()
	{
		let caret = CaretRect(mWordStart);
		let p0 = ConvertToRootSpace(.(caret.X - mCompletion.LabelInset, caret.Y));
		let p1 = ConvertToRootSpace(.(caret.X - mCompletion.LabelInset, caret.Y + caret.Height));
		return .(p0.X, Math.Min(p0.Y, p1.Y), 0.0f, Math.Abs(p1.Y - p0.Y));
	}

	private void PlaceCompletion()
	{
		let dispatcher = EventDispatcher;
		if (dispatcher == null)
			return;
		if (dispatcher.IsPopupOpen(mCompletion))
		{
			dispatcher.SetPopupAnchorRect(mCompletion, CompletionAnchor());
			return;
		}
		// Manual: a press elsewhere is the editor's to close it with, not a press swallowed.
		let options = new PopupOptions();
		options.Kind = .Manual;
		options.HasAnchorRect = true;
		options.AnchorRect = CompletionAnchor();
		options.Placement.Side = .Below;
		options.Placement.Align = .Start;
		options.Placement.Gap = 2.0f;
		options.Placement.Shrink = true;
		options.FitContent = true;
		options.OnClosed = new (reason) => { CompletionClosed(); };
		dispatcher.OpenPopup(this, mCompletion, options);
	}

	private void CompletionClosed()
	{
		if (!mCompleting)
			return;
		mCompleting = false;
		KeyContext = "codeeditor";
	}

	// After a character typed: a trigger opens the list afresh; a word's letter opens it.
	private void CompleteAfterTyping(StringView text)
	{
		if ((mService == null) || (text.Length != 1))
			return;
		let c = text[0];
		let triggers = mService.CompletionTriggers;
		for (int i < triggers.Length)
		{
			if (triggers[i] == c)
			{
				TriggerCompletion(false, c);
				return;
			}
		}
		if (!mCompleting && IsWordByte(c))
			TriggerCompletion(false);
	}

	private void ResetBlink()
	{
		mCaretShown = true;
		mBlink = 0.0f;
		Invalidate();
	}

	private void KeepTicking()
	{
		if (mTicking || (ActionManager == null))
			return;
		mTicking = true;
		let tick = new TickAction(new (elapsed) =>
			{
				let seconds = (float)elapsed.TotalSeconds;
				mDoc.AdvanceClock(seconds);
				if (!IsFocused)
				{
					mTicking = false;
					return false;
				}
				mBlink += seconds;
				if (mBlink >= cBlinkSeconds)
				{
					mBlink -= cBlinkSeconds;
					mCaretShown = !mCaretShown;
					Invalidate();
				}
				return true;
			});
		RunAction(tick);
		tick.ReleaseRef();
	}

	// === Editing ===

	// Each selection's edit, from the last to the first (an edit moves only what follows it), as one
	// undo step; the carets after them where `edit` says (`back` bytes before the end of what it put,
	// 0: its end), moved by the later edits.
	// The selection comes `in`: a 16-byte struct by value beside a `ref` in a delegate call breaks
	// Beef's LLVM codegen ("dereferenceable applied to incompatible type").
	private void EditEach(CodeEditKind kind, delegate bool(in CodeSelection s, ref CodeRange replaced, String put, ref uint32 back) edit)
	{
		if (mReadOnly)
			return;
		let before = scope List<CodeSelection>()..AddRange(mSelections);
		let after = scope List<CodeSelection>()..AddRange(mSelections);
		mDoc.Begin(before, kind);
		for (int i = mSelections.Count - 1; i >= 0; i--)
		{
			var replaced = CodeRange();
			let text = scope String();
			uint32 back = 0; // the caret this many bytes before the end of what it put
			if (!edit(mSelections[i], ref replaced, text, ref back))
				continue;
			let put = mDoc.Replace(replaced, text, kind);
			// `back` bytes before the end of what it put (across its line breaks too).
			var caret = put.Start;
			let upTo = (text.Length >= (int)back) ? text.Length - (int)back : 0;
			for (int k < upTo)
				caret = (text[k] == '\n') ? CodePosition((uint32)(caret.Line + 1), 0) : CodePosition(caret.Line, (uint32)(caret.Column + 1));
			if (back == 0)
				caret = put.End;
			after[i] = .(caret, caret);
			for (int j = i + 1; j < after.Count; j++)
			{
				after[j] = .(CodeDocument.Moved(after[j].Anchor, .Right, replaced, put.End),
					CodeDocument.Moved(after[j].Head, .Right, replaced, put.End));
			}
		}
		mDoc.End(after);
		let primary = mPrimary;
		mSelections.Clear();
		mSelections.AddRange(after);
		mPrimary = Math.Min(primary, mSelections.Count - 1);
		Normalize();
		ResetGoals();
		SelectionsChanged();
	}

	// Each selection's head moved (`extend`: its anchor kept, else collapsed onto it).
	// `in` for the reason EditEach gives.
	private void MoveEach(bool extend, delegate CodePosition(in CodeSelection s, ref float goal) move)
	{
		for (int i < mSelections.Count)
		{
			let s = mSelections[i];
			let head = move(s, ref mGoals[i]);
			mSelections[i] = extend ? CodeSelection(s.Anchor, head) : CodeSelection(head, head);
		}
		mDoc.BreakMerge();
		let goals = scope List<float>()..AddRange(mGoals);
		Normalize();
		if (mGoals.Count != mSelections.Count)
			ResetGoals();
		else
		{
			mGoals.Clear();
			mGoals.AddRange(goals);
		}
		SelectionsChanged();
	}

	// Edits planned against the text as it is (each a range and its new text, none overlapping),
	// applied from the last as one undo step, every selection carried through each: a range's start
	// keeps left, its end and a caret go right.
	private void ApplyPlanned(List<Planned> edits, CodeEditKind kind = .Other)
	{
		if (mReadOnly || edits.IsEmpty)
			return;
		for (int i = 1; i < edits.Count; ++i)
		{
			for (int j = i; (j > 0) && (edits[j - 1].Range.Start < edits[j].Range.Start); --j)
				Swap!(edits[j], edits[j - 1]);
		}
		let before = scope List<CodeSelection>()..AddRange(mSelections);
		let after = scope List<CodeSelection>()..AddRange(mSelections);
		mDoc.Begin(before, kind);
		for (let edit in edits)
		{
			let put = mDoc.Replace(edit.Range, edit.Text, kind);
			for (int i < after.Count)
			{
				let sel = after[i];
				let forward = sel.Anchor <= sel.Head;
				let anchorBias = sel.IsEmpty ? CodeBias.Right : (forward ? CodeBias.Left : CodeBias.Right);
				let headBias = sel.IsEmpty ? CodeBias.Right : (forward ? CodeBias.Right : CodeBias.Left);
				after[i] = .(CodeDocument.Moved(sel.Anchor, anchorBias, edit.Range, put.End),
					CodeDocument.Moved(sel.Head, headBias, edit.Range, put.End));
			}
		}
		mDoc.End(after);
		mSelections.Clear();
		mSelections.AddRange(after);
		Normalize();
		ResetGoals();
		SelectionsChanged();
	}

	// The lines the selections cover, as runs [first, last], in order (a selection ending at a
	// line's start leaves that line out).
	private void LineBlocks(List<uint32> firsts, List<uint32> lasts)
	{
		for (let sel in mSelections)
		{
			let r = sel.Range;
			let first = r.Start.Line;
			let last = ((r.End.Line > r.Start.Line) && (r.End.Column == 0)) ? (uint32)(r.End.Line - 1) : r.End.Line;
			if (!lasts.IsEmpty && (first <= lasts.Back + 1))
			{
				lasts[lasts.Count - 1] = Math.Max(lasts.Back, last);
				continue;
			}
			firsts.Add(first);
			lasts.Add(last);
		}
	}

	// An indent of `columns`, in tabs and spaces as it inserts, appended to `outText`.
	private void IndentText(uint32 columns, String outText)
	{
		var columns;
		if (!mInsertSpaces)
		{
			for (; columns >= mTabSize; columns -= mTabSize)
				outText.Append("\t");
		}
		for (; columns > 0; --columns)
			outText.Append(" ");
	}

	// A line's indent in columns (its tabs to their stops).
	private uint32 IndentColumns(StringView text)
	{
		uint32 columns = 0;
		for (int i = 0; (i < text.Length) && ((text[i] == ' ') || (text[i] == '\t')); ++i)
			columns = (text[i] == '\t') ? (columns / mTabSize + 1) * mTabSize : columns + 1;
		return columns;
	}

	// Whether `text` (a line's text before the caret) ends with one of `list`'s (space-separated)
	// words or marks: a word only where a name does not run on before it.
	private static bool EndsWithAny(StringView text, StringView list)
	{
		var text;
		int end = text.Length;
		while ((end > 0) && ((text[end - 1] == ' ') || (text[end - 1] == '\t')))
			--end;
		text = text.Substring(0, end);
		int at = 0;
		while (at < list.Length)
		{
			while ((at < list.Length) && (list[at] == ' '))
				++at;
			int stop = at;
			while ((stop < list.Length) && (list[stop] != ' '))
				++stop;
			let item = list.Substring(at, stop - at);
			at = stop;
			if ((item.Length == 0) || (item.Length > text.Length) || (text.Substring(text.Length - item.Length, item.Length) != item))
				continue;
			let word = IsNameByte(item[0]);
			if (word && (text.Length > item.Length) && IsNameByte(text[text.Length - item.Length - 1]))
				continue;
			return true;
		}
		return false;
	}

	private static bool IsListed(StringView item, StringView list)
	{
		int at = 0;
		while (at < list.Length)
		{
			while ((at < list.Length) && (list[at] == ' '))
				++at;
			int stop = at;
			while ((stop < list.Length) && (list[stop] != ' '))
				++stop;
			if ((stop > at) && (list.Substring(at, stop - at) == item))
				return true;
			at = stop;
		}
		return false;
	}

	private static bool IsNameByte(char8 c)
	{
		return ((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) || ((c >= '0') && (c <= '9')) || (c == '_') ||
			((uint8)c >= 0x80);
	}

	// The token of the character before `at` on its line (what a caret is "in").
	private CodeToken TokenBefore(CodePosition at)
	{
		if ((mLanguage == null) || (at.Column == 0))
			return .Text;
		for (let span in TokensOf(at.Line))
		{
			if ((span.Start < at.Column) && (at.Column <= span.End))
				return span.Token;
		}
		return .Text;
	}

	private CodeToken TokenAtColumn(uint32 line, uint32 column)
	{
		if (mLanguage == null)
			return .Text;
		for (let span in TokensOf(line))
		{
			if ((span.Start <= column) && (column < span.End))
				return span.Token;
		}
		return .Text;
	}

	private void TypeCharacter(StringView text)
	{
		let lang = mLanguage;
		CodePair opens = null;
		CodePair closes = null;
		for (let pair in lang.AutoClose)
		{
			if ((opens == null) && (pair.Open == text))
				opens = pair;
			if ((closes == null) && (pair.Close == text))
				closes = pair;
		}
		EditEach(.Typing, scope (s, replaced, put, back) =>
			{
				replaced = s.Range;
				let at = replaced.Start;
				let line = mDoc.LineText(at.Line);
				let afterAt = (replaced.End.Line == at.Line) ? (int)replaced.End.Column : line.Length;
				let after = line.Substring(afterAt, line.Length - afterAt);
				let @in = TokenBefore(at);
				let inText = (@in == .String) || (@in == .Comment) || (@in == .Escape);
				// Typing the close the pair put: over it.
				if (s.IsEmpty && (closes != null) && (after.Length >= text.Length) && (after.Substring(0, text.Length) == text) &&
					!((opens != null) && (opens.Open == opens.Close) && inText && (@in != .String)))
				{
					replaced = .(at, .(at.Line, (uint32)(at.Column + (uint32)text.Length)));
					put.Set(text);
					return true;
				}
				// A selection and an open: round it.
				if (!s.IsEmpty && (opens != null))
				{
					put.Set(opens.Open);
					mDoc.TextIn(replaced, put);
					put.Append(opens.Close);
					back = (uint32)opens.Close.Length;
					return true;
				}
				// An open where its close may follow: the pair, the caret between. Not in a string or a
				// comment; a quote not after a name (it's'), nor before one.
				if (s.IsEmpty && (opens != null) && !inText)
				{
					let quote = opens.Open == opens.Close;
					let nextFree = (after.Length == 0) || (after[0] == ' ') || (after[0] == '\t') || (after[0] == ')') ||
						(after[0] == ']') || (after[0] == '}') || (after[0] == ',') || (after[0] == ';');
					let afterName = (at.Column > 0) && IsNameByte(line[(int)at.Column - 1]);
					if (nextFree && !(quote && afterName))
					{
						put.Set(opens.Open);
						put.Append(opens.Close);
						back = (uint32)opens.Close.Length;
						return true;
					}
				}
				// A closing word or mark first on its line: the line outdented to its block's opener.
				let before = scope String(line.Substring(0, (int)at.Column));
				before.Append(text);
				let indent = IndentOf(before);
				let first = StringView(before).Substring((int)indent, before.Length - (int)indent);
				if (s.IsEmpty && !lang.OutdentFirst.IsEmpty && IsListed(first, lang.OutdentFirst) &&
					((after.Length == 0) || !IsNameByte(after[0])))
				{
					// The nearest line above with text: its indent, less a stop unless it opens the block.
					var target = IndentColumns(before);
					for (uint32 up = at.Line; up-- > 0;)
					{
						let above = mDoc.LineText(up);
						if (IndentOf(above) == (uint32)above.Length)
							continue;
						let aboveIndent = IndentColumns(above);
						target = EndsWithAny(above, lang.IndentAfter) ? aboveIndent : ((aboveIndent >= mTabSize) ? (uint32)(aboveIndent - mTabSize) : 0u);
						break;
					}
					if (target < IndentColumns(before))
					{
						replaced = .(.(at.Line, 0), at);
						put.Clear();
						IndentText(target, put);
						put.Append(first);
						return true;
					}
				}
				put.Set(text);
				return true;
			});
	}

	// Backspace between a pair it would have put (both go), or in an indent of spaces (back to the
	// stop before).
	private bool DeleteBackwardSpecial(CodePosition at, out CodeRange replaced)
	{
		replaced = .();
		let line = mDoc.LineText(at.Line);
		let column = (int)at.Column;
		if (mLanguage != null)
		{
			for (let pair in mLanguage.AutoClose)
			{
				StringView open = pair.Open;
				StringView close = pair.Close;
				if ((column >= open.Length) && (column + close.Length <= line.Length) &&
					(line.Substring(column - open.Length, open.Length) == open) && (line.Substring(column, close.Length) == close))
				{
					replaced = .(.(at.Line, (uint32)(column - open.Length)), .(at.Line, (uint32)(column + close.Length)));
					return true;
				}
			}
		}
		if (mInsertSpaces && (at.Column > 0) && (at.Column <= IndentOf(line)))
		{
			bool spaces = true;
			for (int i < column)
				spaces = spaces && (line[i] == ' ');
			if (spaces)
			{
				let stop = (uint32)(at.Column - 1) / mTabSize * mTabSize;
				replaced = .(.(at.Line, (uint32)stop), at);
				return true;
			}
		}
		return false;
	}

	private CodePosition WordLeft(CodePosition at)
	{
		if (at.Column == 0)
			return mDoc.PreviousCharacter(at);
		return .(at.Line, (uint32)PrevWordBoundary(mDoc.LineText(at.Line), (int)at.Column));
	}

	private CodePosition WordRight(CodePosition at)
	{
		let text = mDoc.LineText(at.Line);
		if ((int)at.Column >= text.Length)
			return mDoc.NextCharacter(at);
		return .(at.Line, (uint32)NextWordBoundary(text, (int)at.Column));
	}

	// Smart Home: the line's first character past its indent, or its start when there already.
	private CodePosition LineHome(CodePosition at)
	{
		let indent = IndentOf(mDoc.LineText(at.Line));
		return .(at.Line, (at.Column == indent) ? 0u : indent);
	}

	private static uint32 IndentOf(StringView text)
	{
		uint32 n = 0;
		while (((int)n < text.Length) && ((text[(int)n] == ' ') || (text[(int)n] == '\t')))
			++n;
		return n;
	}

	// A line up or down (`lines` of them), at the goal across (set from the caret when unset).
	private CodePosition Vertical(CodePosition at, int32 lines, ref float goal)
	{
		let place = PlaceOf(at);
		if (goal < 0.0f)
			goal = place.X;
		let target = (int64)place.Row + lines; // by rows: a fold is one, a wrapped line several
		if (target < 0)
			return .(0, 0);
		if (target >= (int64)RowCount)
			return mDoc.End();
		uint32 sub = 0;
		let line = LineOfRow((uint32)target, &sub);
		return .(line, ColumnAt(line, sub, goal));
	}

	private int32 PageLines() => Math.Max(1, (int32)(ContentBounds.Height / LineHeight) - 1);

	// The dispatcher's clipboard (null: no clipboard configured).
	private IClipboard Clipboard
	{
		get
		{
			let dispatcher = EventDispatcher;
			return (dispatcher != null) ? dispatcher.Clipboard : null;
		}
	}

	private void Copy(bool cut)
	{
		let clipboard = Clipboard;
		bool any = false;
		for (let s in mSelections)
			any = any || !s.IsEmpty;
		let text = scope String();
		for (let s in mSelections)
		{
			if (any && s.IsEmpty)
				continue;
			if (!text.IsEmpty)
				text.Append("\n");
			if (any)
				mDoc.TextIn(s.Range, text);
			else // no selection: the caret's whole line, with its line feed (VS Code's)
			{
				text.Append(mDoc.LineText(s.Head.Line));
				text.Append("\n");
			}
		}
		if (clipboard != null)
			clipboard.SetText(text);
		if (!cut || mReadOnly)
			return;
		EditEach(.Other, scope (s, replaced, put, back) =>
			{
				if (any)
					replaced = s.Range;
				else if (s.Head.Line + 1 < mDoc.LineCount)
					replaced = .(.(s.Head.Line, 0), .((uint32)(s.Head.Line + 1), 0));
				else
					replaced = .(.(s.Head.Line, 0), .(s.Head.Line, (uint32)mDoc.LineText(s.Head.Line).Length));
				return !replaced.IsEmpty;
			});
	}

	private void Paste()
	{
		let clipboard = Clipboard;
		if ((clipboard == null) || !clipboard.HasText || mReadOnly)
			return;
		let text = scope String();
		clipboard.GetText(text);
		// As many lines as carets: one to each, in order (several copied, as many pasted).
		let parts = scope List<StringView>();
		{
			int start = 0;
			for (int i = 0; i <= text.Length; ++i)
			{
				if ((i == text.Length) || (text[i] == '\n'))
				{
					parts.Add(StringView(text).Substring(start, i - start));
					start = i + 1;
				}
			}
		}
		let spread = (mSelections.Count > 1) && (parts.Count == mSelections.Count);
		int index = mSelections.Count;
		EditEach(.Other, scope [&] (s, replaced, put, back) =>
			{
				--index; // EditEach goes from the last
				replaced = s.Range;
				put.Set(spread ? parts[index] : (StringView)text);
				return true;
			});
	}

	private void Newline()
	{
		// Each new line as indented as the one it breaks, a stop more after what opens a block;
		// between a bracket pair, the close on a line of its own below.
		EditEach(.Other, scope (s, replaced, put, back) =>
			{
				replaced = s.Range;
				let line = mDoc.LineText(replaced.Start.Line);
				let before = line.Substring(0, (int)replaced.Start.Column);
				let afterAt = (replaced.End.Line == replaced.Start.Line) ? (int)replaced.End.Column : line.Length;
				let after = line.Substring(afterAt, line.Length - afterAt);
				let indent = scope String(line.Substring(0, (int)Math.Min(IndentOf(line), replaced.Start.Column)));
				put.Set("\n");
				put.Append(indent);
				if (mLanguage == null)
					return true;
				let opens = EndsWithAny(before, mLanguage.IndentAfter);
				if (!opens)
					return true;
				IndentText(mTabSize, put);
				for (let pair in mLanguage.Brackets)
				{
					int end = before.Length;
					while ((end > 0) && ((before[end - 1] == ' ') || (before[end - 1] == '\t')))
						--end;
					let open = (end >= pair.Open.Length) && (before.Substring(end - pair.Open.Length, pair.Open.Length) == pair.Open);
					if (open && (after.Length >= pair.Close.Length) && (after.Substring(0, pair.Close.Length) == pair.Close))
					{
						put.Append("\n");
						put.Append(indent);
						back = (uint32)(indent.Length + 1);
						break;
					}
				}
				return true;
			});
	}

	private void Indent()
	{
		// A selection across lines indents them; else to the next tab stop at each caret.
		bool lines = false;
		for (let sel in mSelections)
			lines = lines || (sel.Range.Start.Line != sel.Range.End.Line);
		if (lines)
		{
			IndentLines(false);
			return;
		}
		EditEach(.Typing, scope (s, replaced, put, back) =>
			{
				replaced = s.Range;
				if (!mInsertSpaces)
				{
					put.Set("\t");
					return true;
				}
				let view = View(replaced.Start.Line);
				let column = ShownColumn(view, replaced.Start.Column);
				put.Clear();
				for (uint32 k = (uint32)(mTabSize - column % mTabSize); k > 0; --k)
					put.Append(" ");
				return true;
			});
	}

	// === Tokens ===

	// Tokenizes from the first line not known to agree with the one before, up to `line`: a line is
	// tokenized again where its text changed or its entry state did; the rest keep their tokens.
	private void EnsureLexed(uint32 line)
	{
		if (mLanguage == null)
			return;
		while (mLex.Count < (int)mDoc.LineCount)
			mLex.Add(new LineLex());
		for (uint32 i = mCleanTo; (i <= line) && (i < mDoc.LineCount); ++i)
		{
			let entry = (i == 0) ? CodeLexState() : mLex[(int)i - 1].Exit;
			let lex = mLex[(int)i];
			let hash = mDoc.LineHash(i);
			if (lex.Valid && (lex.Hash == hash) && (lex.Entry == entry))
				continue;
			lex.Valid = true;
			lex.Hash = hash;
			lex.Entry = entry;
			var state = entry;
			mLanguage.Tokenize(mDoc.LineText(i), ref state, lex.Spans);
			lex.Exit = state;
			++lex.Stamp;
			++mTokenized;
		}
		mCleanTo = Math.Max(mCleanTo, Math.Min((uint32)(line + 1), mDoc.LineCount));
	}

	// A token's colour: its part's, else the text's.
	private Color TokenColor(CodeToken token)
	{
		if (token == .Text)
			return TextColor;
		let part = GetPartStyle(CodeTokenName(token));
		return part.HasColor ? part.TextColor : TextColor;
	}

	// === Finding ===

	private void FindChanged()
	{
		mMatchesVersion = uint64.MaxValue;
		UpdateCount();
		Invalidate();
	}

	private void UpdateCount()
	{
		RefreshMatches();
		mFindBar.SetCount(CurrentMatch(), mMatches.Count);
	}

	// The matches, found again when the text, the bar's text or its toggles changed.
	private void RefreshMatches()
	{
		let query = mFindBar.Query;
		let key = mDoc.Version * 4 + (mFindBar.MatchCase ? 1UL : 0UL) + (mFindBar.WholeWord ? 2UL : 0UL);
		if ((mMatchesVersion == key) && (mMatchesQuery == query))
			return;
		mMatchesVersion = key;
		mMatchesQuery.Set(query);
		mMatches.Clear();
		if (query.Length == 0)
			return;
		var from = CodePosition(0, 0);
		while ((mMatches.Count < 100000) && mDoc.Find(query, from, mFindBar.MatchCase, mFindBar.WholeWord, false, let found))
		{
			mMatches.Add(found);
			from = found.End;
			if (found.End == mDoc.End())
				break;
		}
	}

	// === Diagnostics ===

	private void ClearDiagnosticAnchors()
	{
		for (let d in mDiagnostics)
		{
			mDoc.RemoveAnchor(d.Start);
			mDoc.RemoveAnchor(d.End);
		}
		ClearAndDeleteItems!(mDiagnostics);
	}

	// A diagnostic's run as marked: an empty one marks the word at it (or a character).
	private CodeRange MarkedRange(Diagnostic d)
	{
		var r = CodeRange(mDoc.GetAnchor(d.Start), mDoc.GetAnchor(d.End));
		if (r.IsEmpty)
		{
			let text = mDoc.LineText(r.Start.Line);
			let word = WordRangeAt(text, (int)r.Start.Column);
			r = (word.End > word.Start) ? CodeRange(.(r.Start.Line, (uint32)word.Start), .(r.Start.Line, (uint32)word.End))
				: CodeRange(r.Start, mDoc.NextCharacter(r.Start));
		}
		return r;
	}
}

/// What CodeEditor.bf keeps out of the public surface: its key bindings and its marks' parts.
internal static class CodeEditorDetail
{
	public struct Binding
	{
		public String Keys;
		public String Command;

		public this(String keys, String command)
		{
			Keys = keys;
			Command = command;
		}
	}

	public static Binding[23] sBindings = .(
		.("ctrl-slash", cCodeToggleComment),
		.("ctrl-rightbracket", cCodeIndentLines),
		.("ctrl-leftbracket", cCodeOutdentLines),
		.("alt-up", cCodeMoveLinesUp),
		.("alt-down", cCodeMoveLinesDown),
		.("shift-alt-up", cCodeDuplicateLinesUp),
		.("shift-alt-down", cCodeDuplicateLinesDown),
		.("ctrl-shift-k", cCodeDeleteLines),
		.("ctrl-d", cCodeAddNextOccurrence),
		.("ctrl-shift-l", cCodeSelectAllOccurrences),
		.("ctrl-alt-up", cCodeAddCursorAbove),
		.("ctrl-alt-down", cCodeAddCursorBelow),
		.("ctrl-f", cCodeFind),
		.("ctrl-h", cCodeReplace),
		.("ctrl-g", cCodeGoToLine),
		.("f3", cCodeFindNext),
		.("shift-f3", cCodeFindPrevious),
		.("ctrl-space", cCodeComplete),
		.("alt-z", cCodeToggleSoftWrap),
		.("ctrl-shift-leftbracket", cCodeFold),
		.("ctrl-shift-rightbracket", cCodeUnfold),
		.("ctrl-k ctrl-0", cCodeFoldAll),
		.("ctrl-k ctrl-j", cCodeUnfoldAll));

	public static Binding[6] sListBindings = .(
		.("down", cCodeCompletionNext),
		.("up", cCodeCompletionPrevious),
		.("pagedown", cCodeCompletionPageDown),
		.("pageup", cCodeCompletionPageUp),
		.("enter", cCodeCompletionAccept),
		.("escape", cCodeCompletionClose));

	public static String[9] sMarks = .("marker", "breakpoint", "execution", "execution-line", "bookmark", "error", "warning", "info", "hint");
}
