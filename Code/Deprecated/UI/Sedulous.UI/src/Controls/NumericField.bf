using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.UI;

/// A number, edited as text, with spin buttons and a range.
///
/// Not an EditText: it hosts the editing behaviour directly, because the text is a RENDERING of
/// the value rather than the thing being edited. Typing re-parses into the value, and leaving
/// reformats from it.
///
/// Min and Max are members here, which shadows Core's free functions of those names inside the
/// class, so the clamping is spelled as Clamp. The same collision as Slider.
class NumericField : View, ITextEditHost
{
	private const float TextPaddingLeft = 6.0f;
	private const float TextPaddingRight = 6.0f;
	private const float BlinkHalfPeriod = 0.5f;
	/// A page step is ten ordinary ones.
	private const float PageMultiplier = 10.0f;
	private const float DecoGap = 4.0f;

	public Property<float> ButtonWidth = new .(20.0f) ~ delete _;
	public Property<bool> ShowSpinButtons = new .(true) ~ delete _;

	public Event<delegate void(NumericField, double)> OnValueChanged ~ _.Dispose();
	public Event<delegate void(NumericField)> OnEditBegan ~ _.Dispose();
	public Event<delegate void(NumericField)> OnEditEnded ~ _.Dispose();

	private double mValue = 0.0;
	private double mMin = 0.0;
	private double mMax = 100.0;
	private double mStep = 1.0;
	private int32 mDecimalPlaces = 0;

	private String mText = new .() ~ delete _;
	private TextEditingBehavior mBehavior ~ delete _;
	/// True while the field is rewriting its own text from the value, so the parse that
	/// normally follows a change does not fire back at the value it came from.
	private bool mUpdatingText = false;

	private List<GlyphPosition> mGlyphPositions = new .() ~ delete _;
	private bool mGlyphsDirty = true;
	private float mTextWidth = 0.0f;
	private float mScrollOffsetX = 0.0f;

	private float mCursorBlinkResetTime = 0.0f;
	private bool mIsDragging = false;
	/// The click that FOCUSED the field keeps its select-all, so typing replaces the value.
	private bool mSelectAllClick = false;

	private String mPrefixText = new .() ~ delete _;
	private String mSuffixText = new .() ~ delete _;
	private bool mHasPrefixText = false;
	private bool mHasSuffixText = false;
	/// OWNED, and NOT children.
	private View mPrefixView = null;
	private View mSuffixView = null;

	/// 0 for none, 1 for up, -1 for down.
	private int32 mHoveredButton = 0;
	private int32 mPressedButton = 0;
	private float mRepeatTimer = 0.0f;
	private float mRepeatDelay = 0.4f;
	private float mRepeatInterval = 0.05f;

	public this()
	{
		IsFocusable = true;
		IsTabStop = true;
		// Up and down change the value, so focus must not spend them on moving away.
		WantsArrowKeys = true;
		Cursor = .IBeam;

		ButtonWidth.SetOwner(this);
		ShowSpinButtons.SetOwner(this);

		mBehavior = new TextEditingBehavior(this);

		// Only what can appear in a number gets through. The parse still has to cope with what
		// this admits, since it permits "-" and "1.2.3" as well as anything sensible.
		let filter = new InputFilter();
		filter.SetCustomFilter(new (character) =>
			((character >= '0') && (character <= '9')) || (character == '-') || (character == '.'));
		mBehavior.SetFilter(filter);

		UpdateText();
	}

	public ~this()
	{
		ReleaseDeco(ref mPrefixView);
		ReleaseDeco(ref mSuffixView);
	}

	// ---- Value and range --------------------------------------------------------------------

	public double Value => mValue;

	public void SetValue(double value)
	{
		let clamped = Clamp(value, mMin, mMax);
		if (mValue == clamped)
			return;

		mValue = clamped;
		UpdateText();
		OnValueChanged(this, clamped);
	}

	public double MinValue => mMin;
	public double MaxValue => mMax;
	public double Step => mStep;
	public int32 DecimalPlaces => mDecimalPlaces;

	/// Setting one end pushes the other out of its way rather than leaving the range inverted.
	public void SetMin(double value)
	{
		mMin = value;
		if (mMax < mMin)
			mMax = mMin;
		if (mValue < mMin)
			SetValue(mMin);
	}

	public void SetMax(double value)
	{
		mMax = value;
		if (mMin > mMax)
			mMin = mMax;
		if (mValue > mMax)
			SetValue(mMax);
	}

	public void SetStep(double value) => mStep = (value < 0.0) ? 0.0 : value;

	public void SetDecimalPlaces(int32 value)
	{
		mDecimalPlaces = (value < 0) ? 0 : value;
		UpdateText();
	}

	public void Increment() => SetValue(mValue + mStep);
	public void Decrement() => SetValue(mValue - mStep);

	/// The behaviour, for callers that drive the editing directly.
	public TextEditingBehavior Behavior => mBehavior;

	/// It edits its value as text, so it always wants the keyboard.
	public override bool WantsTextInput() => IsEffectivelyEnabled();

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

		if (deco.Context != null)
			deco.Context.DetachView(deco);

		deco.ReleaseRef();
		deco = null;
	}

	// ---- ITextEditHost ----------------------------------------------------------------------

	StringView ITextEditHost.Text => mText;
	int32 ITextEditHost.MaxLength => 0;
	bool ITextEditHost.IsReadOnly => false;
	bool ITextEditHost.IsMultiline => false;
	int32 ITextEditHost.TextCharCount => TextCharCount;
	float ITextEditHost.LineHeight => LineHeight;
	IClipboard ITextEditHost.Clipboard => (Context != null) ? Context.Clipboard : null;
	float ITextEditHost.CurrentTime => (Context != null) ? Context.TotalTime : 0.0f;
	float ITextEditHost.GetCursorYPosition(int32 charIndex) => 0.0f;

	public StringView Text => mText;
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

	void ITextEditHost.ReplaceText(int32 charStart, int32 charLength, StringView replacement)
	{
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
		Invalidate();

		// Parsed LIVE, so a listener sees the value as it is typed, but the text is left
		// exactly as typed: reformatting mid edit would move the caret out from under them.
		if (mUpdatingText)
			return;

		if (ParseValue(mText) case .Ok(let parsed))
		{
			let clamped = Clamp(parsed, mMin, mMax);
			if (mValue != clamped)
			{
				mValue = clamped;
				OnValueChanged(this, mValue);
			}
		}
	}

	int32 ITextEditHost.HitTestPosition(float localX, float localY)
	{
		EnsureGlyphsValid();
		let font = ResolveFont();
		if ((font == null) || (font.Shaper == null))
			return 0;

		let hitX = localX - TextPaddingLeft - GetPrefixWidth() + mScrollOffsetX;
		return font.Shaper.HitTest(font.Font, GlyphSpan, hitX, 0).InsertionIndex;
	}

	int32 ITextEditHost.HitTestGlyphPosition(float glyphX, float glyphY)
	{
		let host = (ITextEditHost)this;
		return host.HitTestPosition(glyphX + TextPaddingLeft + GetPrefixWidth() - mScrollOffsetX,
			glyphY);
	}

	float ITextEditHost.GetCursorXPosition(int32 charIndex)
	{
		EnsureGlyphsValid();
		let font = ResolveFont();
		if ((font == null) || (font.Shaper == null))
			return 0.0f;

		return font.Shaper.GetCursorPosition(font.Font, GlyphSpan, charIndex);
	}

	// ---- Input ------------------------------------------------------------------------------

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled() || (e.Button != .Left))
			return;

		if (ShowSpinButtons.Value && (e.X >= Width - ButtonWidth.Value))
		{
			PressSpinButton(e.Y < Height * 0.5f);
			e.Handled = true;
			return;
		}

		// The click that focused the field keeps the select-all from OnFocusGained, so typing
		// replaces the whole value. Placing the caret starts from the NEXT click.
		if (mSelectAllClick && (e.ClickCount <= 1))
		{
			mSelectAllClick = false;
			ResetBlink();
			e.Handled = true;
			return;
		}

		mSelectAllClick = false;
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

	private void PressSpinButton(bool isUp)
	{
		mPressedButton = isUp ? 1 : -1;
		if (isUp)
			Increment();
		else
			Decrement();

		mRepeatTimer = 0;
		mRepeatDelay = 0.4f;
		if (Context != null)
			Context.GetFocusManager().SetCapture(this);
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (ShowSpinButtons.Value)
		{
			if (e.X >= Width - ButtonWidth.Value)
			{
				mHoveredButton = (e.Y < Height * 0.5f) ? 1 : -1;
				// The buttons are not text, so the I-beam is wrong over them.
				Cursor = .Arrow;
			}
			else
			{
				mHoveredButton = 0;
				Cursor = .IBeam;
			}
		}

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

		if (mPressedButton != 0)
		{
			mPressedButton = 0;
			if (Context != null)
				Context.GetFocusManager().ReleaseCapture();

			e.Handled = true;
			return;
		}

		if (mIsDragging)
		{
			mIsDragging = false;
			if (Context != null)
				Context.GetFocusManager().ReleaseCapture();

			e.Handled = true;
		}
	}

	public override void OnMouseLeave() => mHoveredButton = 0;

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		switch (e.Key)
		{
		case .Up:
			Increment();
			e.Handled = true;
		case .Down:
			Decrement();
			e.Handled = true;
		case .PageUp:
			SetValue(mValue + mStep * PageMultiplier);
			e.Handled = true;
		case .PageDown:
			SetValue(mValue - mStep * PageMultiplier);
			e.Handled = true;
		case .Return:
			CommitText();
			e.Handled = true;
		default:
			mBehavior.HandleKeyDown(e.Key, e.Modifiers);
			ResetBlink();
			e.Handled = true;
		}
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
		if (!IsEffectivelyEnabled())
			return;

		// Only while FOCUSED, so a wheel over a form scrolls the form rather than silently
		// changing a number the pointer happened to be over.
		if (!IsFocused())
			return;

		if (e.DeltaY > 0)
			Increment();
		else if (e.DeltaY < 0)
			Decrement();

		e.Handled = true;
	}

	/// Everything is selected on arrival, so the value is primed to be replaced by typing.
	public override void OnFocusGained()
	{
		mBehavior.SelectAll();
		mSelectAllClick = true;
		ResetBlink();
		OnEditBegan(this);
	}

	public override void OnFocusLost()
	{
		mIsDragging = false;
		mSelectAllClick = false;
		CommitText();
		OnEditEnded(this);
	}

	/// Parses what is there, clamps it, and rewrites the text from the result. Whatever was
	/// typed becomes a properly formatted number, or reverts to one.
	public void CommitText()
	{
		if (ParseValue(mText) case .Ok(let parsed))
		{
			mValue = Clamp(parsed, mMin, mMax);
			OnValueChanged(this, mValue);
		}

		UpdateText();
	}

	// ---- Measure and draw -------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		var textHeight = ResolveStyleFloat(.FontSize, 14.0f);
		if (let font = ResolveFont())
			textHeight = font.Font.Metrics.LineHeight;

		MeasuredSize = .(
			constraints.ConstrainWidth(80.0f + EffectiveButtonWidth + GetPrefixWidth() + GetSuffixWidth()),
			constraints.ConstrainHeight(textHeight + 8.0f));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);

		let background = ResolveStyleDrawable(.Background);
		if (background != null)
			background.Draw(ctx, bounds, GetControlState());
		else
			ctx.VG.FillRect(bounds, Color(30 / 255.0f, 32 / 255.0f, 42 / 255.0f, 1.0f));

		if (ShowSpinButtons.Value)
			DrawSpinButtons(ctx, background);

		if (IsFocused())
			DrawFocusRing(ctx, bounds, background);

		let prefixWidth = GetPrefixWidth();
		let suffixWidth = GetSuffixWidth();
		let textAreaWidth = TextAreaWidth;

		ctx.PushClip(.(TextPaddingLeft, 0,
			Width - TextPaddingLeft - TextPaddingRight - EffectiveButtonWidth, Height));

		if (prefixWidth > 0)
			DrawDecoration(ctx, true, TextPaddingLeft, 0, Height);
		if (suffixWidth > 0)
			DrawDecoration(ctx, false, TextPaddingLeft + prefixWidth + textAreaWidth, 0, Height);

		DrawTextContent(ctx, TextPaddingLeft + prefixWidth);
		ctx.PopClip();

		UpdateSpinRepeat();
	}

	/// A held spin button keeps stepping, after a delay and then at an interval.
	///
	/// Driven from the DRAW rather than an update, and approximated at sixty frames a second.
	/// It works because a held button is redrawing anyway.
	private void UpdateSpinRepeat()
	{
		if (mPressedButton == 0)
			return;

		mRepeatTimer += 1.0f / 60.0f;
		if (mRepeatTimer < mRepeatDelay)
			return;

		if (mPressedButton == 1)
			Increment();
		else
			Decrement();

		mRepeatDelay = mRepeatInterval;
	}

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

	private void DrawTextContent(UIDrawContext ctx, float areaX)
	{
		if (ctx.FontService == null)
			return;

		let font = ResolveFont();
		if (font == null)
			return;

		let lineHeight = font.Font.Metrics.LineHeight;
		let textY = (Height - lineHeight) * 0.5f;

		EnsureGlyphsValid();
		EnsureCursorVisible(font);
		let textX = areaX - mScrollOffsetX;

		if (IsFocused() && mBehavior.IsSelecting && (font.Shaper != null))
		{
			let color = ResolveStyleColor(.SelectionColor,
				Color(60 / 255.0f, 120 / 255.0f, 200 / 255.0f, 80 / 255.0f));
			let selectionStart = font.Shaper.GetCursorPosition(font.Font, GlyphSpan, mBehavior.SelectionStart);
			let selectionEnd = font.Shaper.GetCursorPosition(font.Font, GlyphSpan, mBehavior.SelectionEnd);
			ctx.VG.FillRect(.(textX + selectionStart, textY, selectionEnd - selectionStart, lineHeight), color);
		}

		if (mGlyphPositions.Count > 0)
		{
			var textColor = ResolveStyleColor(.TextColor, Color(220 / 255.0f, 225 / 255.0f, 235 / 255.0f, 1.0f));
			if (!IsEffectivelyEnabled())
				textColor = Palette.ComputeDisabled(textColor);

			ctx.VG.DrawPositionedGlyphs(GlyphSpan, font, textX, textY + font.Font.Metrics.Ascent, textColor);
		}

		if (IsFocused())
			DrawCaret(ctx, font, textX, textY, lineHeight);
	}

	private void DrawCaret(UIDrawContext ctx, CachedFont font, float textX, float textY,
		float lineHeight)
	{
		let elapsed = ((Context != null) ? Context.TotalTime : 0.0f) - mCursorBlinkResetTime;
		if (((int32)(elapsed / BlinkHalfPeriod) % 2) != 0)
			return;

		let cursorX = (font.Shaper != null)
			? font.Shaper.GetCursorPosition(font.Font, GlyphSpan, mBehavior.CursorPosition)
			: 0.0f;
		let color = ResolveStyleColor(.CursorColor, Color(220 / 255.0f, 225 / 255.0f, 235 / 255.0f, 1.0f));
		ctx.VG.FillRect(.(textX + cursorX - 1, textY, 2, lineHeight), color);
	}

	private void DrawSpinButtons(UIDrawContext ctx, Drawable background)
	{
		let buttonX = Width - ButtonWidth.Value;
		let halfHeight = Height * 0.5f;

		DrawSpinButton(ctx, true, buttonX, 0, halfHeight);
		DrawSpinButton(ctx, false, buttonX, halfHeight, halfHeight);

		// The separators take the background's OWN border colour where it has one, so the
		// buttons read as part of the field rather than as something laid over it.
		var separatorColor = ResolveStyleColor(.BorderColor, Color(80 / 255.0f, 85 / 255.0f, 100 / 255.0f, 1.0f));
		if (let rounded = background as RoundedRectDrawable)
			separatorColor = rounded.BorderColor;

		ctx.VG.FillRect(.(buttonX, 1, 1, Height - 2), separatorColor);
		ctx.VG.FillRect(.(buttonX, halfHeight, ButtonWidth.Value, 1), separatorColor);

		DrawSpinArrows(ctx, buttonX, halfHeight);
	}

	private void DrawSpinButton(UIDrawContext ctx, bool isUp, float x, float y, float height)
	{
		let which = isUp ? 1 : -1;
		let state = (mPressedButton == which)
			? ControlState.Pressed
			: ((mHoveredButton == which) ? ControlState.Hover : ControlState.Normal);

		let part = isUp ? "spin-up" : "spin-down";
		if (let drawable = ResolvePartDrawable(part, .Background, state))
		{
			drawable.Draw(ctx, .(x, y, ButtonWidth.Value, height), state);
			return;
		}

		var fill = Color(50 / 255.0f, 55 / 255.0f, 68 / 255.0f, 1.0f);
		if (mPressedButton == which)
			fill = Palette.ComputePressed(fill);
		else if (mHoveredButton == which)
			fill = Palette.ComputeHover(fill);

		ctx.VG.FillRect(.(x, y, ButtonWidth.Value, height), fill);
	}

	private void DrawSpinArrows(UIDrawContext ctx, float buttonX, float halfHeight)
	{
		let color = ResolveStyleColor(.TextColor, Color(220 / 255.0f, 225 / 255.0f, 235 / 255.0f, 1.0f));
		let size = Min(ButtonWidth.Value, halfHeight) * 0.25f;
		let cx = buttonX + ButtonWidth.Value * 0.5f;

		let upCY = halfHeight * 0.5f;
		ctx.VG.BeginPath();
		ctx.VG.MoveTo(cx - size, upCY + size * 0.5f);
		ctx.VG.LineTo(cx + size, upCY + size * 0.5f);
		ctx.VG.LineTo(cx, upCY - size * 0.5f);
		ctx.VG.ClosePath();
		ctx.VG.Fill(color);

		let downCY = halfHeight + halfHeight * 0.5f;
		ctx.VG.BeginPath();
		ctx.VG.MoveTo(cx - size, downCY - size * 0.5f);
		ctx.VG.LineTo(cx + size, downCY - size * 0.5f);
		ctx.VG.LineTo(cx, downCY + size * 0.5f);
		ctx.VG.ClosePath();
		ctx.VG.Fill(color);
	}

	private void DrawDecoration(UIDrawContext ctx, bool isPrefix, float x, float y, float height)
	{
		let hasText = isPrefix ? mHasPrefixText : mHasSuffixText;
		let text = isPrefix ? mPrefixText : mSuffixText;
		let view = isPrefix ? mPrefixView : mSuffixView;

		if (hasText && !text.IsEmpty)
		{
			if (let font = ResolveFont())
			{
				let color = ResolveStyleColor(.TextDimColor,
					ResolveStyleColor(.PlaceholderColor, Color(140 / 255.0f, 150 / 255.0f, 170 / 255.0f, 1.0f)));
				ctx.VG.DrawText(text, font, .(x, y, font.Font.MeasureString(text), height), .Left,
					.Middle, color);
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

	// ---- Internals --------------------------------------------------------------------------

	private CachedFont ResolveFont()
	{
		if ((Context == null) || (Context.FontService == null))
			return null;

		let family = scope String();
		ResolveStyleFontFamily(family);
		return Context.FontService.GetFont(family, ResolveStyleFloat(.FontSize, 14.0f));
	}

	private Span<GlyphPosition> GlyphSpan => mGlyphPositions;

	private float EffectiveButtonWidth => ShowSpinButtons.Value ? ButtonWidth.Value : 0.0f;

	private float TextAreaWidth => Width - EffectiveButtonWidth - TextPaddingLeft -
		TextPaddingRight - GetPrefixWidth() - GetSuffixWidth();

	/// Rewrites the text from the value, and puts the caret at the end.
	private void UpdateText()
	{
		mUpdatingText = true;
		FormatValue(mValue, mDecimalPlaces, mText);
		mGlyphsDirty = true;
		mBehavior.Reset();

		let charCount = TextCharCount;
		mBehavior.CursorPosition = charCount;
		mBehavior.AnchorPosition = charCount;
		mUpdatingText = false;
	}

	private void ResetBlink()
	{
		mCursorBlinkResetTime = (Context != null) ? Context.TotalTime : 0.0f;
		Invalidate();
	}

	private void EnsureGlyphsValid()
	{
		if (!mGlyphsDirty)
			return;

		mGlyphsDirty = false;
		mGlyphPositions.Clear();
		mTextWidth = 0;

		let font = ResolveFont();
		if ((font == null) || mText.IsEmpty)
			return;

		if (font.Shaper != null)
		{
			if (font.Shaper.ShapeText(font.Font, mText, mGlyphPositions) case .Ok(let width))
				mTextWidth = width;
		}
		else
		{
			mTextWidth = font.Font.MeasureString(mText, mGlyphPositions);
		}
	}

	private void EnsureCursorVisible(CachedFont font)
	{
		if ((font == null) || (font.Shaper == null))
			return;

		let cursorX = font.Shaper.GetCursorPosition(font.Font, GlyphSpan, mBehavior.CursorPosition);
		let contentWidth = TextAreaWidth;

		if (cursorX - mScrollOffsetX < 0)
			mScrollOffsetX = cursorX;
		else if (cursorX - mScrollOffsetX > contentWidth)
			mScrollOffsetX = cursorX - contentWidth;

		mScrollOffsetX = Clamp(mScrollOffsetX, 0.0f, Max(0.0f, mTextWidth - contentWidth));
	}

	/// A decoration is not in the child tree, so it has no context of its own. Without ours it
	/// cannot resolve a font, measures to nothing, and the value draws straight over it.
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

	/// The filter admits "-" and "1.2.3" as well as anything sensible, so this has to fail
	/// gracefully rather than assume it was handed a number.
	private static Result<double> ParseValue(StringView text)
	{
		if (text.IsEmpty)
			return .Err;

		return double.Parse(text);
	}

	private static void FormatValue(double value, int32 decimalPlaces, String outText)
	{
		outText.Clear();
		value.ToString(outText, scope $"F{decimalPlaces}", null);
	}
}
