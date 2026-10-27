using System;
using internal Sedulous.GUI;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.GUI;

// TextEditBase: what the text field and the text area share. It holds the editing model: typed
// text goes to it, and every editing key reaches it as a command through the keymap, the widget
// declaring the "textinput" key context and handling the editing commands' names
// (BindTextEditingKeys binds the keys), so a screen rebinds them and a menu shows and runs them
// like any command. A mouse press places the caret, a drag selects, a double press selects a word
// and a triple everything.
//
// It reports each edit as `input` (SetOnTextChanging), and a committed value as `change`
// (SetOnTextChanged) when focus leaves with a value other than the last committed one, or when the
// widget submits (`submit`, SetOnSubmit), as the web's inputs do; code's value reports nothing. An
// IME's composition shows in place, underlined over the selection it will replace, until it
// commits as typed text, and the widget tells the host where it types, for the IME's candidates.
// The caret blinks while it is focused. A context menu (a right release, a long press, Shift+F10)
// offers cut, copy, paste and select all, each lit only where it would do something.
//
// A widget built on it gives the geometry: the layout it edits in (one line, or wrapped), where
// that layout sits (scrolled), and how it scrolls to keep the caret in view.

[GuiReflect, Scriptable]
abstract class TextEditBase : UIWidget
{
	protected const float cCaretWidth = 1.5f;
	/// Seconds per on/off half-cycle.
	private const double cBlinkPeriod = 0.5;
	private const String cBullet = "\u{2022}";
	private const String cMiddleDot = "\u{00B7}";

	// Cut, copy, paste, select all (its child while open); a reference held.
	private Menu mEditMenu = null ~ _?.ReleaseRef();
	// Not owned: the menu's.
	private List<MenuItem> mContextItems = new .() ~ delete _;
	private TextEditModel mModel = new .() ~ delete _;
	// The value last reported as changed.
	private String mCommitted = new .() ~ delete _;
	// An IME's text not yet committed.
	private String mComposition = new .() ~ delete _;
	// Its caret, in characters.
	private int32 mCompositionCursor = 0;
	// What it shows: its value, or its mask.
	private Sedulous.GUI.Text mText = new .() ~ delete _;
	// What bindings reading the text follow.
	private Observable mTextChanged = new .() ~ delete _;

	private String mPlaceholder = new .() ~ delete _;
	// Placeholder renderer (shares the widget's font).
	private Sedulous.GUI.Text mHintText = new .() ~ delete _;
	private Color mPlaceholderColor = .(0.55f, 0.58f, 0.62f, 1.0f);

	private Color mCaretColor = .(0.90f, 0.92f, 0.95f, 1.0f);
	private Color mSelectionColor = .(0.25f, 0.45f, 0.85f, 0.60f);
	private delegate void(StringView text) mOnTextChanging ~ delete _;
	private delegate void(StringView text) mOnTextChanged ~ delete _;
	private delegate void(StringView text) mOnSubmit ~ delete _;

	// Drag-select in progress (pointer is captured).
	private bool mSelecting = false;
	private ShownCaretPlaces mPlaces ~ delete _;
	// A line's share of a range, reused each draw.
	private List<Float2> mRangeBoxes = new .() ~ delete _;

	// Blink state (advances via Update()), and the model's clock.
	private bool mCaretVisible = true;
	private double mBlinkAccum = 0.0;
	private double mClock = 0.0;

	// A blink tick is running.
	private bool mBlinking = false;
	private bool mPlaceholderShown = false;
	// A mark for each character of a password.
	private String mMask = new .(cBullet) ~ delete _;

	protected this()
	{
		mPlaces = new ShownCaretPlaces(this);
		TabFocusable = true;
		KeyContext = "textinput";
		mModel.SetCaretPlaces(mPlaces); // Left and Right across what it shows
		mText.SetAlignment(.Start, .Top);
		mHintText.SetAlignment(.Start, .Top);
		using (StyleWriteScope(this)) // `text-align` from the start, which a sheet changes
		{
			SetTextAlignment(.Start, .Top);
		}
		mHintText.Color = mPlaceholderColor;
		// Each editing command, by the name the keymap binds, runs on its model.
		for (int i = 0; i < (int)TextEditCommand.Count; i++)
		{
			let command = (TextEditCommand)i;
			OnCommand(TextEditCommandName(command), new (e) => { RunEdit(command); });
		}
	}

	// === Value ===

	/// The text (a read a binding records). Set from code: the caret goes to its end and the
	/// history goes; it is the committed value now, and reports no edit (as the web's value does).
	[GuiProperty("text", .TwoWay, "value"), Scriptable]
	public StringView Text
	{
		get
		{
			mTextChanged.Track();
			return mModel.Text;
		}
		set
		{
			if (value == mModel.Text)
				return; // a binding writing back what was typed keeps the caret where it is
			mModel.Text = value;
			mCommitted.Set(value);
			Synced();
			mTextChanged.Notify();
		}
	}

	/// The editing model under it (its history, its rules).
	public TextEditModel Model => mModel;
	/// Its context menu (built on first use).
	public Menu ContextMenu => mEditMenu;

	/// Byte offset of the caret (always on a grapheme boundary).
	public int Caret
	{
		get => mModel.Caret;
		set
		{
			mModel.SetCaret(value);
			CaretMoved();
		}
	}

	/// Each edit, with the text after it (the `input` event). OWNERSHIP of `callback` transfers.
	public void SetOnTextChanging(delegate void(StringView text) callback)
	{
		delete mOnTextChanging;
		mOnTextChanging = callback;
	}

	/// A committed value: a submit, or focus leaving with a new one (the `change` event).
	/// OWNERSHIP of `callback` transfers.
	public void SetOnTextChanged(delegate void(StringView text) callback)
	{
		delete mOnTextChanged;
		mOnTextChanged = callback;
	}

	/// A submit (the `submit` event), after the value commits. OWNERSHIP of `callback` transfers.
	public void SetOnSubmit(delegate void(StringView text) callback)
	{
		delete mOnSubmit;
		mOnSubmit = callback;
	}

	// === Selection ===

	public bool HasSelection => mModel.HasSelection;
	public int SelectionStart => mModel.Selection.Start;
	public int SelectionEnd => mModel.Selection.End;
	public StringView SelectedText => mModel.SelectedText;

	public void SelectAll()
	{
		mModel.SelectAll();
		CaretMoved();
	}

	public void ClearSelection()
	{
		mModel.SetCaret(mModel.Caret);
		CaretMoved();
	}

	// === Placeholder, limits, rules ===

	/// Hint text shown (dimmed) while the value is empty.
	[GuiProperty("placeholder", .Translatable, "description"), Scriptable]
	public StringView Placeholder
	{
		get => mPlaceholder;
		set
		{
			mPlaceholder.Set(value);
			mHintText.SetString(mPlaceholder);
			SyncPlaceholderShown();
			Invalidate();
		}
	}

	public Color PlaceholderColor
	{
		get => mPlaceholderColor;
		set
		{
			mPlaceholderColor = value;
			mHintText.Color = value;
			Invalidate();
		}
	}

	/// A read-only one shows, selects and copies its value but takes no edits (CSS's :read-only;
	/// an editable one is :read-write).
	[GuiProperty("read-only"), Scriptable]
	public bool IsReadOnly
	{
		get => mModel.ReadOnly;
		set
		{
			if (value == mModel.ReadOnly)
				return;
			mModel.ReadOnly = value;
			MarkStyleStateDirty(StateReadOnly | StateReadWrite);
			Invalidate();
		}
	}

	public override uint32 WidgetStates =>
		(IsReadOnly ? WidgetStateNone : WidgetStateEditable) | (mPlaceholderShown ? WidgetStatePlaceholderShown : WidgetStateNone);

	/// The most graphemes it holds (0: no limit); what does not fit is cut.
	[GuiProperty("max-length"), Scriptable]
	public int MaxLength
	{
		get => mModel.MaxLength;
		set => mModel.MaxLength = value;
	}

	/// What it lets in, typed or pasted. OWNERSHIP of `filter` transfers.
	public void SetInputFilter(InputFilter filter)
	{
		mModel.Filter = filter;
	}

	/// The filter by name, as markup and sheets give it: "none", "digits" or "hex-digits".
	[GuiProperty("input-filter"), Scriptable]
	public StringView InputFilterName
	{
		get
		{
			switch (mModel.Filter.Mode)
			{
			case .Digits: return "digits";
			case .HexDigits: return "hex-digits";
			case .Custom: return "custom";
			default: return "none";
			}
		}
		set
		{
			let n = ParseUtil.Trim(value);
			let filter = new InputFilter();
			filter.Mode = (n == "digits") ? InputFilterMode.Digits : (n == "hex-digits") ? InputFilterMode.HexDigits : InputFilterMode.None;
			SetInputFilter(filter);
		}
	}

	/// An enabled one wants platform text input while focused (the bridge enables the window's IME
	/// accordingly).
	public override bool WantsTextInput => IsTreeEnabled;
	/// A masked field (a password): the platform's IME composes nothing in it.
	public override bool IsTextInputSecret => IsMasked;

	// === Appearance ===

	// Theming: the text colour drives the caret too (so it shows on any background); a `::caret` /
	// `::selection` part can override either.
	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("caret");
		outParts.Add("selection");
	}

	public Color CaretColor
	{
		get => mCaretColor;
		set
		{
			mCaretColor = value;
			Invalidate();
		}
	}

	public Color SelectionColor
	{
		get => mSelectionColor;
		set
		{
			mSelectionColor = value;
			Invalidate();
		}
	}

	/// Whether the caret shows now (focused, and in the visible half of its blink).
	public bool IsCaretShown => IsFocused && mCaretVisible;

	/// Advances the caret's blink and the model's clock. A focused one in a GUI drives it itself, on
	/// its root's clock; one in no GUI shows a steady caret unless its owner calls it.
	public void Update(double deltaSeconds)
	{
		mClock += deltaSeconds;
		mModel.Time = mClock;
		if (!IsFocused)
			return;
		mBlinkAccum += deltaSeconds;
		if (mBlinkAccum >= cBlinkPeriod)
		{
			mBlinkAccum -= cBlinkPeriod;
			mCaretVisible = !mCaretVisible;
			Invalidate();
		}
	}

	/// Where it types (its line, from where a composition starts), for the IME's candidates.
	public override bool GetTextInputArea(out Rect outArea, out float outCaretX)
	{
		let layout = EditLayout();
		let origin = TextOrigin(EditBounds());
		let start = DisplayOffset(SelectionStart);
		let end = start + (Composing ? mComposition.Length : 0);
		let line = LineAt(layout, DisplayCaret());
		let left = origin.X + layout.CaretX(start);
		let right = origin.X + layout.CaretX(end);
		outArea = .(left, origin.Y + line.Top, Math.Max(1.0f, right - left), line.Height);
		outCaretX = origin.X + layout.CaretX(DisplayCaret(), CaretUpstream);
		return true;
	}

	// === What a widget built on it gives ===

	/// The layout it edits in (of the shown text).
	protected abstract TextLayout EditLayout();
	/// Where that layout's origin is in the widget (scrolled), for `content`.
	protected abstract Float2 TextOrigin(Rect content);
	/// Scrolls by the least that shows the caret.
	protected abstract void KeepCaretInView();
	/// Where its placeholder draws in `content`.
	protected virtual Rect PlaceholderBounds(Rect content) => content;
	/// Where its text goes: its content box, less any part of its own beside the text (a number
	/// field's arrows).
	protected virtual Rect EditBounds() => ContentBounds;
	/// Whether it masks its text (a password: a bullet for each character).
	protected virtual bool IsMasked => false;
	/// The text is about to commit (Return, focus leaving): a field that reads it as something (a
	/// number field's expression) settles it here, its Text setter making its own the committed
	/// value.
	protected virtual void OnCommitting() { }

	// === For a widget built on it ===

	protected Sedulous.GUI.Text ShownText => mText;
	protected Sedulous.GUI.Text HintText => mHintText;

	/// The line holding display offset `offset`.
	protected static LaidOutLine LineAt(TextLayout layout, int offset)
	{
		return layout.Lines.IsEmpty ? LaidOutLine() : layout.Lines[layout.LineOf(offset)];
	}

	/// Where the caret shows: in a composition, at its cursor (in characters).
	protected int DisplayCaret()
	{
		if (!Composing)
			return DisplayOffset(Caret);
		StringView composition = mComposition;
		int at = 0;
		for (int32 n = 0; (n < mCompositionCursor) && (at < composition.Length); ++n)
			at = TextSegmentationDetail.Utf8NextBoundary(composition, at);
		return SelectionStart + at;
	}

	// The shown text's bytes for a value's offset, and back: a mask a grapheme, or a composition in
	// place of the selection.
	protected int DisplayOffset(int offset)
	{
		if (IsMasked)
			return GraphemeCount(mModel.Text.Substring(0, offset)) * mMask.Length;
		if (!Composing)
			return offset;
		let cut = mModel.Selection;
		if (offset <= cut.Start)
			return offset;
		if (offset >= cut.End)
			return offset - (cut.End - cut.Start) + mComposition.Length;
		return cut.Start;
	}

	protected int ModelOffset(int display)
	{
		if (IsMasked)
		{
			let text = mModel.Text;
			int at = 0;
			for (int n = display / mMask.Length; (n > 0) && (at < text.Length); --n)
				at = NextGrapheme(text, at);
			return at;
		}
		if (!Composing)
			return display;
		let cut = mModel.Selection;
		if (display <= cut.Start)
			return display;
		if (display <= cut.Start + mComposition.Length)
			return cut.Start;
		return display - mComposition.Length + (cut.End - cut.Start);
	}

	protected bool Composing => (mComposition.Length != 0) && !IsMasked;

	/// What the model's text shows as, after it changed or its mask did.
	protected void Synced()
	{
		if (Composing)
		{
			let text = mModel.Text;
			let cut = mModel.Selection;
			let shown = scope String(text.Substring(0, cut.Start));
			shown.Append(mComposition);
			shown.Append(text.Substring(cut.End, text.Length - cut.End));
			mText.SetString(shown);
		}
		else if (IsMasked)
		{
			let mask = scope String();
			let text = mModel.Text;
			for (int at = 0; at < text.Length; at = NextGrapheme(text, at))
				mask.Append(mMask);
			mText.SetString(mask);
		}
		else
		{
			mText.SetString(mModel.Text);
		}
		SyncPlaceholderShown();
		ShowCaret();
		Invalidate();
	}

	/// The value commits, and submits (the `submit` event).
	protected void Submit()
	{
		if (!IsTreeEnabled)
			return;
		Commit();
		if (mOnSubmit != null)
			mOnSubmit(mModel.Text);
		SendEvent(scope Event(.Submit, this));
	}

	// Its own scroll keeps the caret in view, then each scroller round it does (a text area as tall
	// as its text in a scrolling box), as a browser's do while it is typed in.
	protected void ShowCaret()
	{
		KeepCaretInView();
		if (!IsFocused)
			return;
		Rect at;
		if (!GetFocusArea(out at))
			return;
		for (var up = Parent; up != null; up = up.Parent)
		{
			if (up.IsScrollContainer)
				up.ScrollIntoView(this, at, .Nearest, .Instant);
		}
	}

	// Its caret, which a scroller round it keeps in view as its content grows.
	public override bool GetFocusArea(out Rect outArea)
	{
		let layout = EditLayout();
		let origin = TextOrigin(EditBounds());
		let caret = DisplayCaret();
		let line = LineAt(layout, caret);
		let h = (line.Height > 0.0f) ? line.Height : mText.LineHeight;
		outArea = .(origin.X + layout.CaretX(caret, CaretUpstream), origin.Y + line.Top, cCaretWidth, h);
		return true;
	}

	protected void CaretMoved()
	{
		ShowCaret();
		ResetBlink();
		Invalidate();
	}

	// Its value and placeholder draw in its font, its value and caret in its colour.
	protected override void OnTextStyleChange()
	{
		let style = GetTextStyle();
		mText.Font = Font;
		mText.SetFontSelection(FontService, style.FontFamily, style.Selection);
		mHintText.Font = Font;
		mHintText.SetFontSelection(FontService, style.FontFamily, style.Selection);
		mText.Direction = TextDirectionFor();
		mHintText.Direction = TextDirectionFor();
		// Across, as its `text-align` says; down, as the editor places its lines.
		mText.SetAlignment(TextAlignH, mText.VAlign);
		mHintText.SetAlignment(TextAlignH, mHintText.VAlign);
		mText.Color = TextColor;
		mText.LetterSpacing = style.LetterSpacing;
		mText.BreakWords = style.BreakWords;
		mText.SetLineHeight(style.LineHeightPixels);
		mHintText.SetLineHeight(style.LineHeightPixels);
		mCaretColor = TextColor;
		// A password's mark: a bullet, or a middle dot where the font has no bullet.
		mMask.Set(FontDraws(Font, cBullet) ? cBullet : cMiddleDot);
		if (IsMasked)
			Synced();
		KeepCaretInView();
	}

	public override void OnSizeChange()
	{
		ShowCaret();
	}

	protected override void OnTextInput(TextInputEvent e)
	{
		if (!IsTreeEnabled || (e.Text.Length == 0))
			return;
		e.Handled = true;
		mComposition.Clear(); // a composition commits as this text
		if (mModel.Insert(e.Text))
			Edited();
		else
			Synced();
	}

	// An IME's composition so far: shown in place of the selection, the caret within it.
	protected override void OnComposition(CompositionEvent e)
	{
		if (!IsTreeEnabled || IsReadOnly || IsMasked)
			return;
		e.Handled = true;
		mComposition.Set(e.Text);
		mCompositionCursor = Math.Max(0, e.Cursor);
		Synced();
		ResetBlink();
	}

	// The editing keys reach it as commands, through the keymap; a key that types (a letter, a
	// digit, the space bar) is its own, so it neither activates nor moves focus.
	protected override void OnKeyDown(KeyEvent e)
	{
		if (!IsTreeEnabled || (e.Target != this))
			return;
		if ((e.Modifiers & (KeyModCtrl | KeyModAlt | KeyModSuper)) != 0)
			return;
		let key = (KeyCode)e.KeyCode;
		if ((key == .Space) || ((key >= .A) && (key <= .Num9)))
			e.Handled = true;
		// Capturing Tab, it types a tab (no platform sends Tab as text).
		if ((key == .Tab) && (e.Modifiers == 0) && TabCaptures && !IsReadOnly)
		{
			e.Handled = true;
			mComposition.Clear();
			if (mModel.Insert("\t"))
				Edited();
		}
	}

	// Cut, copy, paste and select all, at the event's place, lit where they would do something.
	protected override void OnContextMenu(MouseEvent e)
	{
		e.Handled = true;
		if (mEditMenu == null)
		{
			mEditMenu = new Menu();
			mEditMenu.SetAutoWidth(true);
			AddEditItem("Cut", "gui.cut", .Cut);
			AddEditItem("Copy", "gui.copy", .Copy);
			AddEditItem("Paste", "gui.paste", .Paste);
			mEditMenu.AddSeparator();
			AddEditItem("Select all", "gui.select-all", .SelectAll);
		}
		let selected = HasSelection && mModel.CopyAllowed;
		let clipboard = Clipboard;
		mContextItems[0].Enabled = selected && !IsReadOnly;
		mContextItems[1].Enabled = selected;
		mContextItems[2].Enabled = !IsReadOnly && (clipboard != null) && clipboard.HasText;
		mContextItems[3].Enabled = mModel.Text.Length != 0;
		// Each shows the keys the GUI binds to its command ("Ctrl+X").
		TextEditCommand[4] commands = .(.Cut, .Copy, .Paste, .SelectAll);
		let scene = SceneRoot;
		if (scene != null)
		{
			// The keys bound in the field's own contexts ("textinput"): the ones that work here.
			let contexts = scope List<KeyContextLayer>();
			defer { ClearAndDeleteItems!(contexts); }
			scene.KeyContextsAt(this, contexts);
			for (int i = 0; i < mContextItems.Count; i++)
			{
				let shortcut = scope String();
				scene.Context.Keymap.ShortcutText(TextEditCommandName(commands[i]), (Span<KeyContextLayer>)contexts, shortcut);
				mContextItems[i].Shortcut = shortcut;
			}
		}
		let root = RootNode;
		mEditMenu.Open(this, (root != null) ? root.ConvertToNodeSpace(e.Position) : e.Position);
	}

	// A press selects text: a drag from what holds it is not offered.
	public override bool OwnsPressDrag(Float2 local) => true;

	protected override void OnMouseDown(MouseEvent e)
	{
		RequestFocus();
		e.Handled = true;
		// Only the primary button places the caret: a right press keeps the selection a context
		// menu would act on.
		if (e.Button != .Left)
			return;
		let shift = (e.Modifiers & KeyModShift) != 0;
		bool upstream;
		let pos = OffsetAtPoint(ConvertToNodeSpace(e.Position), out upstream);

		// A double press selects the word, a triple everything (the dispatcher counts them).
		if ((e.ClickCount >= 2) && !shift)
		{
			if ((e.ClickCount == 2) && !IsMasked)
				mModel.SelectWordAt(pos);
			else
				mModel.SelectAll(); // a password is one word
			mSelecting = false;
			CaretMoved();
			return;
		}
		mModel.SetCaret(pos, shift, upstream); // Shift extends from the anchor
		mSelecting = true; // begin a drag-select (pointer is captured)
		CaretMoved();
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		if (!mSelecting)
			return;
		bool upstream;
		let pos = OffsetAtPoint(ConvertToNodeSpace(e.Position), out upstream);
		mModel.SetCaret(pos, true, upstream);
		CaretMoved();
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		mSelecting = false;
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		mSelecting = false;
	}

	protected override void OnFocusGained()
	{
		ResetBlink();
		if (!mBlinking && (ActionManager != null))
		{
			// Blinks while focused: the tick ends itself when focus goes (and goes with the widget
			// if the widget does).
			mBlinking = true;
			let tick = new TickAction(new (elapsed) =>
				{
					if (!IsFocused)
					{
						mBlinking = false;
						return false;
					}
					Update(elapsed.TotalSeconds);
					return true;
				});
			RunAction(tick);
			tick.ReleaseRef();
		}
	}

	protected override void OnFocusLost()
	{
		mCaretVisible = false;
		mSelecting = false;
		if (mComposition.Length != 0)
		{
			mComposition.Clear(); // an unfinished composition goes with the focus
			Synced();
		}
		Commit();
		KeepCaretInView(); // unfocused: back to the start of its line
		Invalidate();
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		let content = EditBounds();
		// What it shows stays inside its padding (the caret's width past the right, so a caret there
		// shows).
		ctx.PushClip(.(content.X, content.Y, content.Width + cCaretWidth, content.Height));

		if ((mModel.Text.Length == 0) && (mPlaceholder.Length > 0) && !Composing)
		{
			mHintText.Draw(ctx, PlaceholderBounds(content));
		}
		else
		{
			let layout = EditLayout();
			let origin = TextOrigin(content);
			// The selection sits behind the text (a composition replaces it).
			if (IsFocused && HasSelection && !Composing)
				DrawRange(ctx, layout, origin, DisplayOffset(SelectionStart), DisplayOffset(SelectionEnd), false);
			mText.DrawLayout(ctx, layout, origin);
			if (Composing)
			{
				// The composition underlined, as IMEs show text not yet committed.
				let start = DisplayOffset(SelectionStart);
				DrawRange(ctx, layout, origin, start, start + mComposition.Length, true);
			}
		}

		if (IsFocused && mCaretVisible && (!HasSelection || Composing))
		{
			let layout = EditLayout();
			let origin = TextOrigin(content);
			let caret = DisplayCaret();
			let line = LineAt(layout, caret);
			let h = (line.Height > 0.0f) ? line.Height : mText.LineHeight;
			GetPartStyle("caret").Draw(ctx, .(origin.X + layout.CaretX(caret, CaretUpstream), origin.Y + line.Top, cCaretWidth, h),
				FilledBox(mCaretColor, scope NodeBox()));
		}
		ctx.PopClip();
	}

	// A range of the shown text, line by line: the selection behind it, or a composition's
	// underline.
	private void DrawRange(DrawContext ctx, TextLayout layout, Float2 origin, int start, int end, bool underline)
	{
		for (int i = 0; i < layout.Lines.Count; i++)
		{
			let line = layout.Lines[i];
			let a = Math.Max(start, line.Start);
			let b = Math.Min(end, line.End);
			// A range running on past a line that ends at a break takes the break in.
			let wraps = (i + 1 < layout.Lines.Count) && (layout.Lines[i + 1].Start == line.End);
			let takesBreak = !wraps && (end > line.End) && (i + 1 < layout.Lines.Count);
			if ((a > b) || ((a == b) && !takesBreak))
				continue;
			// In pieces where directions mix; a break taken in shows past the line's end.
			layout.RangeOnLine(a, b, i, mRangeBoxes);
			if (takesBreak && !underline)
			{
				let breakX = layout.CaretXOnLine(line.End, i, true);
				mRangeBoxes.Add(line.RightToLeft ? Float2(breakX - 4.0f, breakX) : Float2(breakX, breakX + 4.0f));
			}
			for (let @box in mRangeBoxes)
			{
				if (underline)
				{
					ctx.VG.FillRect(.(origin.X + @box.X, origin.Y + line.Top + line.Height - 1.0f, @box.Y - @box.X, 1.0f), mText.Color);
				}
				else
				{
					GetPartStyle("selection").Draw(ctx, .(origin.X + @box.X, origin.Y + line.Top, @box.Y - @box.X, line.Height),
						FilledBox(mSelectionColor, scope NodeBox()));
				}
			}
		}
	}

	// Where the caret shows: after the text before it (the model's affinity) unless composing.
	private bool CaretUpstream => !Composing && mModel.IsCaretUpstream;

	// Where carets stand in what it shows: the layout's, offsets mapped through the mask or the
	// composition.
	private class ShownCaretPlaces : ITextCaretPlaces
	{
		// Its widget, which owns it.
		private TextEditBase mEdit;

		public this(TextEditBase edit)
		{
			mEdit = edit;
		}

		public bool OffsetVisually(int offset, bool upstream, int32 step, out int outOffset, out bool outUpstream)
		{
			let layout = mEdit.EditLayout();
			if (layout.GlyphRuns.IsEmpty)
			{
				// Nothing shaped (no font yet): by a grapheme, as the bytes go.
				let text = mEdit.mModel.Text;
				outOffset = (step < 0) ? PrevGrapheme(text, offset) : NextGrapheme(text, offset);
				outUpstream = false;
				return true;
			}
			if (!layout.OffsetVisually(mEdit.DisplayOffset(offset), upstream, step, let display, out outUpstream))
			{
				outOffset = offset; // there is none that way: it stays
				return false;
			}
			outOffset = mEdit.ModelOffset(display);
			return true;
		}

		public bool IsRightToLeftAt(int offset)
		{
			let layout = mEdit.EditLayout();
			return !layout.Lines.IsEmpty && layout.Lines[layout.LineOf(mEdit.DisplayOffset(offset))].RightToLeft;
		}
	}

	// === The model's changes ===

	// An edit item, its label translated (`key`: gui.cut, ...) where the GUI's tables have it, else
	// `label`, English.
	private void AddEditItem(StringView label, StringView key, TextEditCommand command)
	{
		let item = mEditMenu.AddItem(label, new () => { RunEdit(command); });
		item.BindTranslation("text", key, null, null, Span<Node.TranslationArgument>(), label);
		mContextItems.Add(item);
	}

	private void RunEdit(TextEditCommand command)
	{
		if (!IsTreeEnabled)
			return;
		let version = mModel.Version;
		mModel.Run(command, Clipboard);
		if (mModel.Version != version)
			Edited();
		else
			CaretMoved();
	}

	// An edit the user made: shown, followed, reported.
	private void Edited()
	{
		Synced();
		ResetBlink();
		mTextChanged.Notify();
		if (mOnTextChanging != null)
			mOnTextChanging(mModel.Text);
		SendEvent(scope Event(.Input, this));
	}

	// The value commits: reported once for each new value.
	private void Commit()
	{
		OnCommitting();
		if (mModel.Text == mCommitted)
			return;
		mCommitted.Set(mModel.Text);
		if (mOnTextChanged != null)
			mOnTextChanged(mModel.Text);
		SendEvent(scope Event(.Changed, this));
	}

	// :placeholder-shown follows whether the value is empty under a placeholder.
	private void SyncPlaceholderShown()
	{
		let shown = (mModel.Text.Length == 0) && (mPlaceholder.Length != 0);
		if (shown == mPlaceholderShown)
			return;
		mPlaceholderShown = shown;
		MarkStyleStateDirty(StatePlaceholderShown);
	}

	private void ResetBlink()
	{
		mCaretVisible = true;
		mBlinkAccum = 0.0;
		Invalidate();
	}

	// The dispatcher's clipboard adapter (may be null: no clipboard configured).
	private IClipboard Clipboard
	{
		get
		{
			let dispatcher = EventDispatcher;
			return (dispatcher != null) ? dispatcher.Clipboard : null;
		}
	}

	private int OffsetAtPoint(Float2 local, out bool upstream)
	{
		let origin = TextOrigin(EditBounds());
		return ModelOffset(EditLayout().OffsetAt(.(local.X - origin.X, local.Y - origin.Y), out upstream));
	}
}
