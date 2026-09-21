using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.VG;

namespace Sedulous.UI;

/// A text field: one line or many, with selection, clipboard, undo and input filtering.
///
/// The editing LOGIC lives in TextEditingBehavior; this owns the text, does the font work and
/// fires the events. That split is what lets one behaviour drive this, a password box and a
/// multiline editor without knowing which it is in.
///
/// The ITextEditHost members are EXPLICIT implementations, because several of them collide by
/// name with this class's own Property fields; an explicit implementation resolves the clash
/// without renaming the interface's members.
class EditText : View, ITextEditHost
{
	/// How long the caret stays on, and off, in seconds.
	private const float BlinkHalfPeriod = 0.5f;
	/// A wheel notch moves this many lines.
	private const float WheelLines = 3.0f;
	/// The gap between a prefix or suffix and the text it sits beside.
	private const float DecoGap = 4.0f;

	public Property<String> Placeholder = new .(new String()) ~ delete _;
	public Property<bool> IsReadOnly = new .(false) ~ delete _;
	public Property<bool> Multiline = new .(false) ~ delete _;
	/// The longest text allowed, in characters. Nought means unlimited.
	public Property<int32> MaxLength = new .(0) ~ delete _;

	/// Whether a right click offers Cut, Copy, Paste and Select All.
	public bool ShowContextMenuOnRightClick = true;

	public Event<delegate void(EditText)> OnTextChanged ~ _.Dispose();
	/// Enter, or an activation. NOT fired on blur.
	public Event<delegate void(EditText)> OnSubmit ~ _.Dispose();
	/// Focus was lost, whether or not anything changed. The neutral blur hook.
	public Event<delegate void(EditText)> OnEditingFinished ~ _.Dispose();
	/// The COMMIT: Enter or activation, and blur when the text changed since focus was gained.
	///
	/// This is the one to subscribe for entering a value. A typed-then-clicked-away edit is
	/// never dropped, and an untouched field never re-commits on the way out. OnSubmit stays
	/// Enter-only, for consumers whose activation does something else as well.
	public Event<delegate void(EditText)> OnCommit ~ _.Dispose();

	protected String mText = new .() ~ delete _;
	/// What the text was when focus arrived, so blur can tell whether to commit.
	protected String mTextAtFocusGain = new .() ~ delete _;
	protected TextEditingBehavior mBehavior ~ delete _;
	protected bool mIsDragging = false;

	// The glyph cache: reshaped on demand rather than every draw.
	protected List<GlyphPosition> mGlyphPositions = new .() ~ delete _;
	protected String mCachedDisplayText = new .() ~ delete _;
	protected bool mGlyphsDirty = true;
	protected float mTextWidth = 0.0f;
	protected float mTextHeight = 0.0f;

	protected float mScrollOffsetX = 0.0f;
	protected float mScrollOffsetY = 0.0f;
	protected float mCursorBlinkResetTime = 0.0f;
	protected bool mNeedsCursorScroll = false;

	protected String mPrefixText = new .() ~ delete _;
	protected String mSuffixText = new .() ~ delete _;
	protected bool mHasPrefixText = false;
	protected bool mHasSuffixText = false;
	/// OWNED, and NOT children: a decoration is drawn by hand, so it is never focusable or
	/// separately hit tested.
	protected View mPrefixView = null;
	protected View mSuffixView = null;

	public this()
	{
		IsFocusable = true;
		IsTabStop = true;
		// The arrows move the caret, so focus must not spend them on moving away.
		WantsArrowKeys = true;
		Cursor = .IBeam;

		mBehavior = new TextEditingBehavior(this);

		Placeholder.SetOwner(this, .Visual);
		IsReadOnly.SetOwner(this, .Visual);
		Multiline.SetOwner(this);
		MaxLength.SetOwner(this);

		// Wrapping and single line shape differently, so the cache cannot survive the switch.
		Multiline.Changed.Add(new (val) => { mGlyphsDirty = true; });
	}

	public ~this()
	{
		delete Placeholder.Value;
		ReleaseDeco(ref mPrefixView);
		ReleaseDeco(ref mSuffixView);
	}

	// ---- Text -------------------------------------------------------------------------------

	public StringView Text => mText;

	public void SetText(StringView text)
	{
		mText.Set(text);
		mGlyphsDirty = true;
		// The caret and selection belonged to the old text and mean nothing against the new.
		mBehavior.Reset();
		Invalidate();
	}

	public void SetPlaceholder(StringView text)
	{
		Placeholder.Value.Set(text);
		Invalidate();
	}

	/// The behaviour, for callers that drive the editing directly.
	public TextEditingBehavior Behavior => mBehavior;

	public InputFilter Filter => mBehavior.Filter;
	public void SetFilter(InputFilter filter) => mBehavior.SetFilter(filter);

	public int32 CursorPosition => mBehavior.CursorPosition;
	public int32 SelectionStart => mBehavior.SelectionStart;
	public int32 SelectionEnd => mBehavior.SelectionEnd;

	/// Wants platform text input while focused, unless read only. That covers PasswordBox, and
	/// EditableLabel, which toggles IsReadOnly between its label and edit modes.
	public override bool WantsTextInput() => IsEffectivelyEnabled() && !IsReadOnly.Value;

	// ---- Prefix and suffix ------------------------------------------------------------------

	public void SetPrefix(StringView text)
	{
		ReleaseDeco(ref mPrefixView);
		mPrefixText.Set(text);
		mHasPrefixText = true;
		Invalidate();
	}

	/// CONSUMES the caller's reference.
	public void SetPrefix(View view)
	{
		ReleaseDeco(ref mPrefixView);
		mHasPrefixText = false;
		mPrefixText.Clear();
		mPrefixView = view;
		Invalidate();
	}

	public void SetSuffix(StringView text)
	{
		ReleaseDeco(ref mSuffixView);
		mSuffixText.Set(text);
		mHasSuffixText = true;
		Invalidate();
	}

	/// CONSUMES the caller's reference.
	public void SetSuffix(View view)
	{
		ReleaseDeco(ref mSuffixView);
		mHasSuffixText = false;
		mSuffixText.Clear();
		mSuffixView = view;
		Invalidate();
	}

	private void ReleaseDeco(ref View deco)
	{
		if (deco == null)
			return;

		// Given our context by hand in SyncDecoContext, so taken back by hand: a view released
		// while still registered leaves the context holding a dangling pointer.
		if (deco.Context != null)
			deco.Context.DetachView(deco);

		deco.ReleaseRef();
		deco = null;
	}

	// ---- ITextEditHost ----------------------------------------------------------------------

	StringView ITextEditHost.Text => mText;
	int32 ITextEditHost.MaxLength => MaxLength.Value;
	bool ITextEditHost.IsReadOnly => IsReadOnly.Value;
	bool ITextEditHost.IsMultiline => Multiline.Value;
	int32 ITextEditHost.TextCharCount => TextCharCount;
	float ITextEditHost.LineHeight => LineHeight;
	IClipboard ITextEditHost.Clipboard => (Context != null) ? Context.Clipboard : null;
	float ITextEditHost.CurrentTime => (Context != null) ? Context.TotalTime : 0.0f;

	void ITextEditHost.ReplaceText(int32 charStart, int32 charLength, StringView replacement)
	{
		// The behaviour counts in CHARACTERS; the buffer is bytes, and only we know that.
		let byteStart = Utf8Text.CharToByteOffset(mText, charStart);
		let byteEnd = Utf8Text.CharToByteOffset(mText, charStart + charLength);

		mText.Remove(byteStart, byteEnd - byteStart);
		mText.Insert(byteStart, replacement);
		mGlyphsDirty = true;
	}

	void ITextEditHost.OnTextModified()
	{
		mGlyphsDirty = true;
		mCursorBlinkResetTime = (Context != null) ? Context.TotalTime : 0.0f;
		mNeedsCursorScroll = true;
		Invalidate();
		OnTextChanged(this);
	}

	int32 ITextEditHost.HitTestPosition(float localX, float localY)
	{
		EnsureGlyphsValid();
		let font = ResolveFont();
		if ((font == null) || (font.Shaper == null))
			return FallbackHitTest(localX);

		let chrome = ContentInset;
		let hitX = localX - chrome.Left - GetPrefixWidth() + mScrollOffsetX;
		let hitY = localY - chrome.Top + mScrollOffsetY;

		if (Multiline.Value)
			return MultilineHitTest(font, hitX, hitY);

		return font.Shaper.HitTest(font.Font, GlyphSpan, hitX, 0).InsertionIndex;
	}

	int32 ITextEditHost.HitTestGlyphPosition(float glyphX, float glyphY)
	{
		EnsureGlyphsValid();
		let font = ResolveFont();
		if ((font == null) || (font.Shaper == null))
			return 0;

		if (Multiline.Value)
			return MultilineHitTest(font, glyphX, glyphY);

		return font.Shaper.HitTest(font.Font, GlyphSpan, glyphX, 0).InsertionIndex;
	}

	float ITextEditHost.GetCursorXPosition(int32 charIndex)
	{
		EnsureGlyphsValid();
		let font = ResolveFont();
		if ((font == null) || (font.Shaper == null))
			return 0.0f;

		if (!Multiline.Value)
			return font.Shaper.GetCursorPosition(font.Font, GlyphSpan, charIndex);

		return GetMultilineCursorX(charIndex);
	}

	float ITextEditHost.GetCursorYPosition(int32 charIndex)
	{
		EnsureGlyphsValid();
		let font = ResolveFont();
		if (font == null)
			return 0.0f;

		return GetCursorYFromCharIndex(charIndex, font.Font.Metrics.LineHeight);
	}

	/// The number of CHARACTERS, not bytes.
	public int32 TextCharCount => Utf8Text.CharCount(mText);

	public float LineHeight
	{
		get
		{
			let font = ResolveFont();
			if (font == null)
				return ResolveStyleFloat(.FontSize, 14.0f);

			return font.Font.Metrics.LineHeight;
		}
	}

	/// How far the multiline text is scrolled, so an external gutter can line its per-line
	/// markers up with the visible rows.
	public float ScrollOffsetY => mScrollOffsetY;

	// ---- Input ------------------------------------------------------------------------------

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		if ((e.Button == .Right) && ShowContextMenuOnRightClick)
		{
			ShowContextMenu(e.X, e.Y);
			e.Handled = true;
			return;
		}

		if (e.Button != .Left)
			return;

		// A double or triple click selects a word or a line and does NOT start a drag: the
		// press that made it is already spent.
		if (e.ClickCount <= 1)
		{
			mIsDragging = true;
			if (Context != null)
				Context.GetFocusManager().SetCapture(this);
		}

		mBehavior.HandleMouseDown(e.X, e.Y, e.ClickCount, e.Modifiers);
		ResetBlink();
		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mIsDragging)
		{
			mBehavior.HandleMouseMove(e.X, e.Y);
			ResetBlink();
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (e.Button != .Left)
			return;

		if (mIsDragging)
		{
			mIsDragging = false;
			if (Context != null)
				Context.GetFocusManager().ReleaseCapture();

			e.Handled = true;
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		// On one line, Return submits rather than inserting; multiline keeps it as a newline.
		if ((e.Key == .Return) && !Multiline.Value)
		{
			OnSubmit(this);
			e.Handled = true;
			return;
		}

		mBehavior.HandleKeyDown(e.Key, e.Modifiers);
		ResetBlink();
		e.Handled = true;
	}

	public override void OnTextInput(TextInputEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		mBehavior.HandleTextInput(e.Character);
		ResetBlink();
		e.Handled = true;
	}

	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		if (!Multiline.Value)
			return;

		let contentHeight = Height - ContentInset.TotalVertical;
		let maxScrollY = Max(0.0f, mTextHeight - contentHeight);
		if (maxScrollY <= 0)
			return;

		mScrollOffsetY = Clamp(mScrollOffsetY - e.DeltaY * LineHeight * WheelLines, 0.0f, maxScrollY);
		Invalidate();
		e.Handled = true;
	}

	public override void OnFocusGained()
	{
		ResetBlink();
		mTextAtFocusGain.Set(mText);
	}

	public override void OnFocusLost()
	{
		mIsDragging = false;
		OnEditingFinished(this);

		if (mText != mTextAtFocusGain)
		{
			// Rebased BEFORE the event, so a handler that moves focus again cannot commit twice.
			mTextAtFocusGain.Set(mText);
			OnCommit(this);
		}
	}

	public override void OnActivate()
	{
		OnSubmit(this);
		// Committed here, so the blur that follows does not commit the same edit again.
		mTextAtFocusGain.Set(mText);
		OnCommit(this);
	}

	// ---- Measure and draw -------------------------------------------------------------------

	/// What to paint. PasswordBox overrides this to mask.
	public virtual void GetDisplayText(String outText) => outText.Set(mText);

	/// The content's offset from the view origin: the SAME chrome the base measure reserved.
	/// Draw, caret, hit testing and scrolling all read this one thing.
	public Thickness ContentInset => ResolveBoxMetrics().Chrome;

	protected override Thickness DefaultStylePadding() => .(6, 4);

	protected override Float2 OnMeasureContent(BoxConstraints contentConstraints)
	{
		var textHeight = ResolveStyleFloat(.FontSize, 14.0f);
		if (let font = ResolveFont())
		{
			textHeight = font.Font.Metrics.LineHeight;
			// A multiline field opens three rows tall, which is enough to read as one.
			if (Multiline.Value)
				textHeight *= 3.0f;
		}

		let minWidth = 100.0f + GetPrefixWidth() + GetSuffixWidth();
		return .(contentConstraints.ConstrainWidth(minWidth),
			contentConstraints.ConstrainHeight(textHeight));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);
		let fontSize = ResolveStyleFloat(.FontSize, 14.0f);
		let chrome = ContentInset;

		let background = ResolveStyleDrawable(.Background);
		if (background != null)
			background.Draw(ctx, bounds, GetControlState());
		else
			ctx.VG.FillRect(bounds, Color(30 / 255.0f, 32 / 255.0f, 42 / 255.0f, 1.0f));

		if (IsFocused())
			DrawFocusRing(ctx, bounds, background);

		let contentX = chrome.Left;
		let contentY = chrome.Top;
		let contentWidth = Width - chrome.TotalHorizontal;
		let contentHeight = Height - chrome.TotalVertical;
		let prefixWidth = GetPrefixWidth();
		let suffixWidth = GetSuffixWidth();

		ctx.PushClip(.(contentX, contentY, contentWidth, contentHeight));
		if (prefixWidth > 0)
			DrawPrefix(ctx, contentX, contentY, contentHeight);
		if (suffixWidth > 0)
			DrawSuffix(ctx, contentX + contentWidth - suffixWidth, contentY, contentHeight);

		DrawTextContent(ctx, contentX + prefixWidth, contentY,
			contentWidth - prefixWidth - suffixWidth, contentHeight, fontSize);
		ctx.PopClip();
	}

	/// The focus ring follows the background's own corners, so a rounded field does not get a
	/// square ring drawn across it.
	private void DrawFocusRing(UIDrawContext ctx, Rectangle bounds, Drawable background)
	{
		let accent = ResolveStyleColor(.AccentColor,
			ResolveStyleColor(.CursorColor, Color(80 / 255.0f, 160 / 255.0f, 1.0f, 1.0f)));

		if (let rounded = background as RoundedRectDrawable)
		{
			if (!rounded.Radii.IsZero)
				ctx.VG.StrokeRoundedRect(bounds, rounded.Radii, accent, 2.0f);
			else
				ctx.VG.StrokeRect(bounds, accent, 2.0f);

			return;
		}

		let radius = ResolveStyleFloat(.CornerRadius);
		if (radius > 0)
			ctx.VG.StrokeRoundedRect(bounds, radius, accent, 2.0f);
		else
			ctx.VG.StrokeRect(bounds, accent, 2.0f);
	}

	/// The text, its selection and its caret, into a content rect. Protected so EditableLabel
	/// can reuse it.
	protected void DrawTextContent(UIDrawContext ctx, float areaX, float areaY, float areaWidth,
		float areaHeight, float fontSize)
	{
		if (ctx.FontService == null)
			return;

		let font = ResolveFont();
		if (font == null)
			return;

		let lineHeight = font.Font.Metrics.LineHeight;
		// Multiline runs from the top and scrolls; one line is centred on the field.
		let textY = Multiline.Value ? (areaY - mScrollOffsetY) : (areaY + (areaHeight - lineHeight) * 0.5f);

		EnsureGlyphsValid();
		if (mNeedsCursorScroll)
		{
			EnsureCursorVisible(font);
			mNeedsCursorScroll = false;
		}

		let textX = areaX - mScrollOffsetX;

		// The placeholder shows only while UNFOCUSED: a focused empty field shows its caret
		// against nothing, which is what says it is ready for typing.
		let placeholder = Placeholder.Value;
		if (mText.IsEmpty && !IsFocused() && !placeholder.IsEmpty)
		{
			let placeholderColor = ResolveStyleColor(.PlaceholderColor,
				Color(140 / 255.0f, 150 / 255.0f, 170 / 255.0f, 1.0f));
			ctx.VG.DrawText(placeholder, font, .(areaX, areaY, areaWidth, areaHeight), .Left,
				Multiline.Value ? .Top : .Middle, placeholderColor);
		}
		else
		{
			if (IsFocused() && mBehavior.IsSelecting && (font.Shaper != null))
				DrawSelection(ctx, font, textX, textY, lineHeight);

			DrawGlyphs(ctx, font, textX, textY);
		}

		if (IsFocused() && !IsReadOnly.Value)
			DrawCaret(ctx, font, textX, textY, lineHeight);
	}

	private void DrawSelection(UIDrawContext ctx, CachedFont font, float textX, float textY,
		float lineHeight)
	{
		let color = ResolveStyleColor(.SelectionColor,
			Color(60 / 255.0f, 120 / 255.0f, 200 / 255.0f, 80 / 255.0f));

		if (Multiline.Value)
		{
			// A wrapped selection is one box per line, so the shaper hands back several.
			let rects = scope List<FontRect>();
			font.Shaper.GetSelectionRects(font.Font, GlyphSpan,
				SelectionRange(CharToGlyphIndex(mBehavior.SelectionStart),
					CharToGlyphIndex(mBehavior.SelectionEnd)), lineHeight, rects);

			for (let rect in rects)
				ctx.VG.FillRect(.(textX + rect.X, textY + rect.Y, rect.Width, rect.Height), color);

			return;
		}

		let selectionStart = font.Shaper.GetCursorPosition(font.Font, GlyphSpan, mBehavior.SelectionStart);
		let selectionEnd = font.Shaper.GetCursorPosition(font.Font, GlyphSpan, mBehavior.SelectionEnd);
		ctx.VG.FillRect(.(textX + selectionStart, textY, selectionEnd - selectionStart, lineHeight), color);
	}

	private void DrawGlyphs(UIDrawContext ctx, CachedFont font, float textX, float textY)
	{
		if (mGlyphPositions.Count == 0)
			return;

		var textColor = ResolveStyleColor(.TextColor, Color(220 / 255.0f, 225 / 255.0f, 235 / 255.0f, 1.0f));
		if (!IsEffectivelyEnabled())
			textColor = Palette.ComputeDisabled(textColor);

		// The glyphs were positioned from the BASELINE, so the ascent goes back on here.
		ctx.VG.DrawPositionedGlyphs(GlyphSpan, font, textX, textY + font.Font.Metrics.Ascent, textColor);
	}

	private void DrawCaret(UIDrawContext ctx, CachedFont font, float textX, float textY,
		float lineHeight)
	{
		let elapsed = ((Context != null) ? Context.TotalTime : 0.0f) - mCursorBlinkResetTime;
		if (((int32)(elapsed / BlinkHalfPeriod) % 2) != 0)
			return;

		var cursorX = 0.0f;
		if (font.Shaper != null)
		{
			cursorX = Multiline.Value
				? GetMultilineCursorX(mBehavior.CursorPosition)
				: font.Shaper.GetCursorPosition(font.Font, GlyphSpan, mBehavior.CursorPosition);
		}

		let cursorY = Multiline.Value ? GetCursorYFromCharIndex(mBehavior.CursorPosition, lineHeight) : 0;
		let color = ResolveStyleColor(.CursorColor, Color(220 / 255.0f, 225 / 255.0f, 235 / 255.0f, 1.0f));
		ctx.VG.FillRect(.(textX + cursorX - 1, textY + cursorY, 2, lineHeight), color);
	}

	// ---- Context menu -----------------------------------------------------------------------

	/// The right click menu: Cut, Copy, Paste and Select All, each offered only when it would
	/// do something.
	private void ShowContextMenu(float localX, float localY)
	{
		if (Context == null)
			return;

		let menu = new ContextMenu();
		defer menu.ReleaseRef(); // Show takes its own; from then on the layer holds it

		if (!IsReadOnly.Value)
			menu.AddItem("Cut", new () => { mBehavior.HandleKeyDown(.X, .Ctrl); }, mBehavior.IsSelecting);

		menu.AddItem("Copy", new () => { mBehavior.HandleKeyDown(.C, .Ctrl); }, mBehavior.IsSelecting);

		if (!IsReadOnly.Value)
		{
			let hasClipboardText = (Context.Clipboard != null) && Context.Clipboard.HasText;
			menu.AddItem("Paste", new () => { mBehavior.HandleKeyDown(.V, .Ctrl); }, hasClipboardText);
		}

		menu.AddSeparator();
		menu.AddItem("Select All", new () => { mBehavior.HandleKeyDown(.A, .Ctrl); });

		let screen = LocalToScreen(.(localX, localY));
		menu.Show(Context, screen.X, screen.Y);
	}

	// ---- Fonts and shaping ------------------------------------------------------------------

	protected CachedFont ResolveFont()
	{
		if ((Context == null) || (Context.FontService == null))
			return null;

		let family = scope String();
		ResolveStyleFontFamily(family);
		return Context.FontService.GetFont(family, ResolveStyleFloat(.FontSize, 14.0f));
	}

	protected Span<GlyphPosition> GlyphSpan => mGlyphPositions;

	private void ResetBlink()
	{
		mCursorBlinkResetTime = (Context != null) ? Context.TotalTime : 0.0f;
		mNeedsCursorScroll = true;
		Invalidate();
	}

	/// Reshapes only when something that feeds the shaping has changed.
	protected void EnsureGlyphsValid()
	{
		if (!mGlyphsDirty)
			return;

		mGlyphsDirty = false;
		mGlyphPositions.Clear();
		mTextWidth = 0;
		mTextHeight = 0;

		let font = ResolveFont();
		if (font == null)
			return;

		mCachedDisplayText.Clear();
		GetDisplayText(mCachedDisplayText);
		if (mCachedDisplayText.IsEmpty)
			return;

		if (Multiline.Value && (font.Shaper != null))
		{
			let chrome = ContentInset;
			let contentWidth = Width - chrome.TotalHorizontal - GetPrefixWidth() - GetSuffixWidth();
			if (font.Shaper.ShapeTextWrapped(font.Font, mCachedDisplayText, contentWidth,
				mGlyphPositions, var totalHeight) case .Ok)
			{
				mTextHeight = totalHeight;
				// The widest LINE, which is what a horizontal scroll would have to cover.
				for (let glyph in mGlyphPositions)
					mTextWidth = Max(mTextWidth, glyph.X + glyph.Advance);
			}
		}
		else if (font.Shaper != null)
		{
			if (font.Shaper.ShapeText(font.Font, mCachedDisplayText, mGlyphPositions) case .Ok(let width))
				mTextWidth = width;

			mTextHeight = font.Font.Metrics.LineHeight;
		}
		else
		{
			// No shaper: measured rather than shaped, which is enough to size the field.
			mTextWidth = font.Font.MeasureString(mCachedDisplayText, mGlyphPositions);
			mTextHeight = font.Font.Metrics.LineHeight;
		}
	}

	/// Scrolls the least that brings the caret back into the content box.
	private void EnsureCursorVisible(CachedFont font)
	{
		if ((font == null) || (font.Shaper == null))
			return;

		let chrome = ContentInset;

		if (!Multiline.Value)
		{
			let cursorX = font.Shaper.GetCursorPosition(font.Font, GlyphSpan, mBehavior.CursorPosition);
			let contentWidth = Width - chrome.TotalHorizontal - GetPrefixWidth() - GetSuffixWidth();

			if (cursorX - mScrollOffsetX < 0)
				mScrollOffsetX = cursorX;
			else if (cursorX - mScrollOffsetX > contentWidth)
				mScrollOffsetX = cursorX - contentWidth;

			mScrollOffsetX = Clamp(mScrollOffsetX, 0.0f, Max(0.0f, mTextWidth - contentWidth));
			return;
		}

		let lineHeight = font.Font.Metrics.LineHeight;
		let contentHeight = Height - chrome.TotalVertical;
		let cursorY = GetCursorYFromCharIndex(mBehavior.CursorPosition, lineHeight);

		if (cursorY - mScrollOffsetY < 0)
			mScrollOffsetY = cursorY;
		else if (cursorY + lineHeight - mScrollOffsetY > contentHeight)
			mScrollOffsetY = cursorY + lineHeight - contentHeight;

		mScrollOffsetY = Clamp(mScrollOffsetY, 0.0f, Max(0.0f, mTextHeight - contentHeight));
	}

	// ---- Multiline geometry -----------------------------------------------------------------

	private int32 MultilineHitTest(CachedFont font, float hitX, float hitY)
	{
		let lineHeight = font.Font.Metrics.LineHeight;
		let targetLine = Max(0, (int32)(hitY / lineHeight));
		let charCount = TextCharCount;
		let lineCharStart = GetCharIndexForLine(targetLine);

		if (lineCharStart >= charCount)
			return charCount;

		// An EMPTY line has no glyph to hit, so the shaper cannot answer for it.
		if (CharAt(mCachedDisplayText, lineCharStart) == '\n')
			return lineCharStart;

		if (hitX <= 0)
			return lineCharStart;

		let result = font.Shaper.HitTestWrapped(font.Font, GlyphSpan, hitX, hitY, lineHeight);
		return GlyphToCharIndex(result.InsertionIndex, result.IsTrailingHit);
	}

	/// The character index the given line starts at.
	private int32 GetCharIndexForLine(int32 line)
	{
		if (line <= 0)
			return 0;

		var currentLine = 0;
		int32 index = 0;
		for (let character in mCachedDisplayText.DecodedChars)
		{
			if (character == '\n')
			{
				currentLine++;
				if (currentLine == line)
					return index + 1;
			}
			index++;
		}

		return TextCharCount;
	}

	private float GetMultilineCursorX(int32 charIndex)
	{
		if ((mGlyphPositions.Count == 0) || (charIndex == 0))
			return 0.0f;

		// Just past a newline means the START of the next line, which no glyph reports.
		if (CharAt(mCachedDisplayText, charIndex - 1) == '\n')
			return 0.0f;

		for (int i < mGlyphPositions.Count)
		{
			let glyph = mGlyphPositions[i];
			if (glyph.StringIndex == charIndex)
				return glyph.X;

			if (glyph.StringIndex > charIndex)
			{
				// Skipped past: the index belongs to the end of the previous line.
				if (i > 0)
				{
					let previous = mGlyphPositions[i - 1];
					if (glyph.Y != previous.Y)
						return previous.X + previous.Advance;
				}
				return 0.0f;
			}
		}

		let last = mGlyphPositions[mGlyphPositions.Count - 1];
		return last.X + last.Advance;
	}

	/// A glyph insertion index back to a character index.
	///
	/// The two differ where a line WRAPPED: the break consumed no character, so the glyph
	/// either side of it can belong to indices that are not adjacent.
	private int32 GlyphToCharIndex(int32 glyphInsertionIndex, bool isTrailingHit)
	{
		if (mGlyphPositions.Count == 0)
			return 0;

		if (glyphInsertionIndex <= 0)
			return mGlyphPositions[0].StringIndex;

		if (glyphInsertionIndex >= mGlyphPositions.Count)
			return mGlyphPositions[mGlyphPositions.Count - 1].StringIndex + 1;

		let previous = mGlyphPositions[glyphInsertionIndex - 1];
		let next = mGlyphPositions[glyphInsertionIndex];

		if ((next.Y != previous.Y) && (next.StringIndex > previous.StringIndex + 1))
			return isTrailingHit ? previous.StringIndex + 1 : next.StringIndex;

		return previous.StringIndex + 1;
	}

	private int32 CharToGlyphIndex(int32 charIndex)
	{
		for (int i < mGlyphPositions.Count)
		{
			if (mGlyphPositions[i].StringIndex >= charIndex)
				return (int32)i;
		}
		return (int32)mGlyphPositions.Count;
	}

	private float GetCursorYFromCharIndex(int32 charIndex, float lineHeight)
	{
		var line = 0;
		var index = 0;
		for (let character in mCachedDisplayText.DecodedChars)
		{
			if (index >= charIndex)
				break;
			if (character == '\n')
				line++;
			index++;
		}

		return line * lineHeight;
	}

	/// With no shaper, the average character width is the best guess going.
	private int32 FallbackHitTest(float localX)
	{
		let hitX = localX - ContentInset.Left + mScrollOffsetX;
		let charCount = TextCharCount;
		if ((charCount == 0) || (mTextWidth <= 0))
			return 0;

		let averageWidth = mTextWidth / charCount;
		return Clamp((int32)(hitX / averageWidth + 0.5f), 0, charCount);
	}

	// ---- Prefix and suffix drawing ----------------------------------------------------------

	/// A decoration is not in the child tree, so it has no context of its own. Without ours it
	/// cannot resolve a font, measures to nothing, and the text draws straight over it.
	private void SyncDecoContext(View view)
	{
		if ((view != null) && (view.Context != Context))
			view.Context = Context;
	}

	private float GetPrefixWidth() => GetDecoWidth(mHasPrefixText, mPrefixText, mPrefixView);
	private float GetSuffixWidth() => GetDecoWidth(mHasSuffixText, mSuffixText, mSuffixView);

	private float GetDecoWidth(bool hasText, String text, View view)
	{
		if (hasText && !text.IsEmpty)
		{
			if (let font = ResolveFont())
				return font.Font.MeasureString(text) + DecoGap;
		}
		else if (view != null)
		{
			SyncDecoContext(view);
			view.Measure(BoxConstraints.Loose(200, 200));
			return view.MeasuredSize.X + DecoGap;
		}

		return 0.0f;
	}

	private void DrawPrefix(UIDrawContext ctx, float x, float y, float height)
	{
		DrawDeco(ctx, mHasPrefixText, mPrefixText, mPrefixView, x, y, height, GetPrefixWidth());
	}

	private void DrawSuffix(UIDrawContext ctx, float x, float y, float height)
	{
		// Inset by the gap, so the suffix sits clear of the text rather than against it.
		DrawDeco(ctx, mHasSuffixText, mSuffixText, mSuffixView, x + DecoGap, y, height,
			GetSuffixWidth());
	}

	private void DrawDeco(UIDrawContext ctx, bool hasText, String text, View view, float x, float y,
		float height, float width)
	{
		if (hasText && !text.IsEmpty)
		{
			if (let font = ResolveFont())
			{
				let color = ResolveStyleColor(.TextDimColor,
					ResolveStyleColor(.PlaceholderColor, Color(140 / 255.0f, 150 / 255.0f, 170 / 255.0f, 1.0f)));
				ctx.VG.DrawText(text, font, .(x, y, width - DecoGap, height), .Left, .Middle, color);
			}
			return;
		}

		if (view == null)
			return;

		SyncDecoContext(view);
		let size = view.MeasuredSize;
		let decoY = y + (height - size.Y) * 0.5f;
		view.Layout(x, decoY, size.X, size.Y);

		ctx.VG.PushState();
		ctx.VG.Translate(x, decoY);
		view.OnDraw(ctx);
		ctx.VG.PopState();
	}

	// ---- UTF-8 ------------------------------------------------------------------------------

	/// The character at an index, or nought past the end.
	private static char32 CharAt(StringView text, int32 charIndex)
	{
		var index = 0;
		for (let character in text.DecodedChars)
		{
			if (index == charIndex)
				return character;
			index++;
		}
		return 0;
	}
}
