using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The purpose-built code editor over [[CodeDocument]].
///
/// Virtualized monospace rendering: only the visible lines are drawn, and column geometry is
/// column times advance, which is what lets a large file scroll without measuring text. A line
/// number gutter carries clickable markers (breakpoints, diagnostics, the execution line), and
/// the whole of the editing surface runs over CodeDocument's delta undo.
///
/// The completion seam is the part that shaped the input design. Composable
/// [[ICompletionProvider]]s feed a [[CompletionModel]] whose popup is SELF-DRAWN inside this
/// widget, deliberately not through PopupLayer.ShowPopup, which pushes and clears focus. The
/// editor has to keep focus, and the IME routing that comes with it, while the popup routes its
/// own keys.
///
/// Keys it acts on are consumed and everything else is left alone, so application shortcuts
/// (save, command palette) keep working while the editor is focused. Tab needs the core's
/// WantsTabKey opt-in, which is dispatch first and traversal only as a fallback.
///
/// Split across files: this one holds state and the seams, with input, layout, drawing and the
/// find bar in their own extensions.
class CodeEditView : ViewGroup, ITooltipProvider
{
	protected const float PadTop = 4.0f;
	protected const float PadLeft = 6.0f;
	protected const float MarkerMargin = 18.0f;
	protected const float NumberPad = 4.0f;
	protected const float GutterGap = 8.0f;
	protected const int32 PopupMaxVisible = 8;

	// ---- appearance and behaviour knobs, read each frame like the other toolkit widgets ----

	public float FontSize = 13.0f;
	/// Falls back to the default family when the service does not have this one.
	public String FontFamily = new .("Mono") ~ delete _;
	/// Spaces per indent step. Tabs insert spaces.
	public int32 TabWidth = 4;
	public bool ShowGutter = true;
	public bool ShowLineNumbers = true;
	public bool ReadOnly = false;
	/// A click in the marker margin toggles a breakpoint.
	public bool AllowBreakpoints = true;
	/// The built-in identifier provider.
	public bool DocumentWordCompletion = true;
	/// Identifier characters typed before the popup opens on its own.
	public int32 AutoCompleteMinPrefix = 2;
	/// Enter after an open brace adds one extra indent step.
	public bool IndentAfterOpenBrace = true;
	/// Typing any of these ASCII characters opens completion immediately with an EMPTY prefix,
	/// so providers can read the document left of the cursor for context. That is how member
	/// access on a dot works without the editor knowing anything about the language.
	public String CompletionTriggerCharacters = new .(".") ~ delete _;

	/// Colours per token kind. Restyle freely.
	public CodeTokenColors TokenColors = .();

	/// Any document mutation: typing, undo, paste.
	public Event<delegate void()> OnTextChanged ~ _.Dispose();
	/// (line, nowSet) after a gutter toggle.
	public Event<delegate void(int32, bool)> OnBreakpointToggled ~ _.Dispose();

	/// Hover value lookup, for debugger integration: given the identifier under the mouse,
	/// append its display text to `outValue`. Leaving it empty means there is nothing to show,
	/// and a diagnostic on that line remains the fallback.
	public delegate void(StringView, String) HoverValueProvider ~ delete _;

	// ---- state ----

	private CodeDocument mDoc = new .() ~ delete _;
	private CodePosition mCursor = .();
	private CodePosition mAnchor = .();
	/// The goal column for vertical motion. Minus one means none is held.
	private int32 mDesiredColumn = -1;

	private float mScrollX = 0.0f;
	private float mScrollY = 0.0f;
	private float mViewportW = 0.0f;
	private float mViewportH = 0.0f;
	/// OWNED, and NOT logical children: released by hand, and detached first, because a view
	/// released while still registered leaves the context holding a dangling pointer.
	private ScrollBar mVBar;
	private ScrollBar mHBar;

	private float mLineHeight = 0.0f;
	private float mAdvance = 0.0f;
	private int32 mMaxLineLength = 0;
	private bool mMaxLineDirty = true;
	private bool mPendingCursorScroll = false;
	private bool mDragging = false;
	private float mBlinkReset = 0.0f;

	/// OWNED.
	private ICodeLexer mLexer = null;
	private CodeHighlighter mHighlighter = new .() ~ delete _;

	// Find bar. Built lazily, and a logical child so hit testing and DrawChildren apply.
	private CodeFindBarMode mFindBarMode = .Closed;
	/// All BORROWED once added: the child list owns them.
	private FlexLayout mFindBar = null;
	private FlexLayout mFindRow = null;
	private FlexLayout mReplaceRow = null;
	private EditText mFindField = null;
	private EditText mReplaceField = null;
	private Label mMatchLabel = null;
	private Button mPrevButton = null;
	private Button mNextButton = null;
	private ToggleButton mCaseButton = null;
	private ToggleButton mWordButton = null;
	private Button mReplaceButton = null;
	private Button mReplaceAllButton = null;
	private Button mCloseButton = null;
	private Rectangle mFindBarFrame = .();
	private bool mSearchCaseSensitive = false;
	private bool mSearchWholeWord = false;
	private List<CodeSpan> mMatches = new .() ~ delete _;
	private int32 mCurrentMatch = -1;

	// Bracket match cache, recomputed when the cursor or the content changes.
	private bool mBracketValid = false;
	private CodePosition mBracketA = .();
	private CodePosition mBracketB = .();
	private uint64 mBracketVersion = uint64.MaxValue;
	private CodePosition mBracketCursor = .();
	private CodePosition mBracketAnchor = .();

	/// Where the pointer last was, for the diagnostics tooltip.
	private Float2 mLastHover = .Zero;

	private CompletionModel mCompletion = new .() ~ delete _;
	private DocumentWordCompletionProvider mWordProvider = new .() ~ delete _;
	/// BORROWED: the caller keeps each provider alive while it is registered.
	private List<ICompletionProvider> mProviders = new .() ~ delete _;

	private String mScratch = new .() ~ delete _;

	public this()
	{
		IsFocusable = true;
		IsTabStop = true;
		WantsArrowKeys = true;
		WantsTabKey = true;
		ClipsContent = true;
		Cursor = .IBeam;
		// Per line diagnostics: the content varies BY REGION, so anchoring to the whole
		// view's bounds would land nowhere near the line being hovered.
		TooltipPlacement = .Pointer;

		mVBar = new ScrollBar(false);
		mVBar.Parent = this;
		mVBar.OnValueChanged.Add(new (bar, value) =>
			{
				mScrollY = value;
				Invalidate();
			});

		mHBar = new ScrollBar(true);
		mHBar.Parent = this;
		mHBar.OnValueChanged.Add(new (bar, value) =>
			{
				mScrollX = value;
				Invalidate();
			});

		mDoc.OnLinesChanged = new (first, removed, added) =>
			{
				mMaxLineDirty = true;
				mHighlighter.OnLinesChanged(first, removed, added);
			};
	}

	public ~this()
	{
		ReleaseBar(ref mVBar);
		ReleaseBar(ref mHBar);

		if (mLexer != null)
			delete mLexer;
	}

	private void ReleaseBar(ref ScrollBar bar)
	{
		if (bar == null)
			return;

		if (bar.Context != null)
			bar.Context.DetachView(bar);

		bar.Parent = null;
		bar.ReleaseRef();
		bar = null;
	}

	// ---- document access --------------------------------------------------------------------

	/// BORROWED.
	public CodeDocument Document => mDoc;

	public void GetText(String outText) => mDoc.GetText(outText);

	public void SetText(StringView text)
	{
		mDoc.SetText(text);
		mCursor = .();
		mAnchor = .();
		mDesiredColumn = -1;
		mScrollX = 0.0f;
		mScrollY = 0.0f;
		mCompletion.Close();
		mMaxLineDirty = true;
		Invalidate();
	}

	public CodePosition CursorPosition => mCursor;

	public void SetCursorPosition(CodePosition pos)
	{
		mCursor = mDoc.ClampPosition(pos);
		mAnchor = mCursor;
		mDesiredColumn = -1;
		mPendingCursorScroll = true;
		ResetBlink();
		Invalidate();
	}

	/// Types `text` at the cursor, replacing any selection, as ONE discrete undo unit. The seam
	/// for external inserters such as an API browser or snippet tooling, which is why it is
	/// paste-kind: it must never coalesce with the keystrokes around it.
	public void InsertAtCursor(StringView text)
	{
		if (text.IsEmpty)
			return;

		InsertText(text, .Paste);
	}

	public bool HasSelection => !(mCursor == mAnchor);

	public CodeSpan Selection => CodeSpan(mAnchor, mCursor).Normalized;

	public void GetSelectedText(String outText) => mDoc.GetTextInSpan(Selection, outText);

	public void SelectAll()
	{
		mAnchor = .();
		mCursor = mDoc.EndPosition;
		Invalidate();
	}

	public float ScrollX => mScrollX;
	public float ScrollY => mScrollY;

	/// Scrolls so `line` is visible, roughly centred, and puts the cursor on it.
	public void ScrollToLine(int32 line)
	{
		let clamped = Math.Clamp(line, 0, mDoc.LineCount - 1);
		SetCursorPosition(.(clamped, 0));
		mScrollY = Math.Max(0.0f, ((float)clamped * LineHeight) - (mViewportH * 0.5f));
		ClampScroll();
		Invalidate();
	}

	// ---- completion -------------------------------------------------------------------------

	/// BORROWED: the caller keeps the provider alive while it is registered.
	public void AddCompletionProvider(ICompletionProvider provider)
	{
		if (provider != null)
			mProviders.Add(provider);
	}

	/// BORROWED.
	public CompletionModel Completion => mCompletion;

	/// Opens the popup at the current word. The explicit Ctrl+Space path.
	public void RequestCompletion() => OpenCompletion(true);

	// ---- syntax highlighting ----------------------------------------------------------------

	/// TAKES OWNERSHIP. Null disables highlighting, leaving plain single colour text.
	public void SetLexer(ICodeLexer lexer)
	{
		if (mLexer != null)
			delete mLexer;

		mLexer = lexer;
		mHighlighter.SetLexer(mLexer);
		mHighlighter.Reset(mDoc.LineCount);
		Invalidate();
	}

	/// BORROWED.
	public CodeHighlighter Highlighter => mHighlighter;

	// ---- tooltip ----------------------------------------------------------------------------

	public override ITooltipProvider AsTooltipProvider() => this;

	public View CreateTooltipContent()
	{
		// A debugger hover value for the identifier under the mouse wins; a diagnostic on the
		// hovered line is the fallback.
		if (HoverValueProvider != null)
		{
			let word = mDoc.WordAt(PositionAt(mLastHover.X, mLastHover.Y));
			if (!word.IsEmpty)
			{
				mScratch.Clear();
				mDoc.GetTextInSpan(word, mScratch);

				let value = scope String();
				HoverValueProvider(mScratch, value);
				if (!value.IsEmpty)
				{
					let label = new Label();
					label.FontSize.Value = 12.0f;
					label.SetText(value);
					return label;
				}
			}
		}

		let line = (int32)((mLastHover.Y + mScrollY - PadTop) / LineHeight);
		if ((line < 0) || (line >= mDoc.LineCount))
			return null;

		let diagnostic = mDoc.DiagnosticOn(line);
		if (diagnostic == null)
			return null;

		let label = new Label();
		label.FontSize.Value = 12.0f;
		label.SetText(diagnostic.Message);
		return label;
	}

	// ---- metrics ----------------------------------------------------------------------------
	// The fallbacks keep the headless tests working with no font service attached.

	public float LineHeight => (mLineHeight > 0.0f) ? mLineHeight : (FontSize * 1.35f);

	public float ColumnAdvance => (mAdvance > 0.0f) ? mAdvance : (FontSize * 0.6f);

	public float GutterWidth
	{
		get
		{
			if (!ShowGutter)
				return 0.0f;

			var digitsWidth = 0.0f;
			if (ShowLineNumbers)
			{
				int32 digits = 1;
				for (var n = mDoc.LineCount; n >= 10; n /= 10)
					digits++;

				digitsWidth = ((float)Math.Max(digits, 3) * ColumnAdvance) + NumberPad;
			}

			return MarkerMargin + digitsWidth + GutterGap;
		}
	}

	/// The buffer position for a point in view local coordinates.
	public CodePosition PositionAt(float localX, float localY)
	{
		let line = (int32)((localY + mScrollY - PadTop) / LineHeight);
		let textX = localX - (GutterWidth + PadLeft) + mScrollX;
		let column = (int32)((textX / ColumnAdvance) + 0.5f);
		return mDoc.ClampPosition(.(line, column));
	}

	protected float Now => (Context != null) ? Context.TotalTime : 0.0f;

	protected void ResetBlink() => mBlinkReset = Now;
}
