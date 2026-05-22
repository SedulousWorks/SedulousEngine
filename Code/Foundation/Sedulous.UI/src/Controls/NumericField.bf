namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;
using Sedulous.VG;

/// Numeric input field with optional integrated up/down spin buttons.
/// Self-contained: owns its own TextEditingBehavior for text editing.
public class NumericField : View, ITextEditHost
{
	// === Value state ===
	private double mValue;
	private double mMin;
	private double mMax = 100;
	private double mStep = 1;
	private int32 mDecimalPlaces;

	// === Text editing ===
	private String mText = new .() ~ delete _;
	private TextEditingBehavior mBehavior ~ delete _;
	private bool mUpdatingText;

	// === Glyph cache ===
	private List<GlyphPosition> mGlyphPositions = new .() ~ delete _;
	private bool mGlyphsDirty = true;
	private float mTextWidth;
	private float mScrollOffsetX;

	// === Cursor blink ===
	private float mCursorBlinkResetTime;
	private bool mIsDragging;

	// === Layout ===
	/// Width of the spin button area when ShowSpinButtons is true.
	public float ButtonWidth = 20;

	/// Whether to show spin buttons on the right side.
	public bool ShowSpinButtons = true;

	// === Prefix/Suffix ===
	private String mPrefixText ~ delete _;
	private View mPrefixView ~ delete _;
	private String mSuffixText ~ delete _;
	private View mSuffixView ~ delete _;

	// === Spin button state ===
	private int8 mHoveredButton; // 0=none, 1=up, -1=down
	private int8 mPressedButton;
	private float mRepeatTimer;
	private float mRepeatDelay = 0.4f;
	private float mRepeatInterval = 0.05f;

	public Event<delegate void(NumericField, double)> OnValueChanged ~ _.Dispose();

	// Transactional edit events for consumers that need to know when the
	// user starts/finishes interacting (typing, dragging). OnValueChanged
	// fires per keystroke during edits; OnEditBegan/Ended bracket the
	// session and let listeners defer rebuilds until the user is done.
	public Event<delegate void(NumericField)> OnEditBegan ~ _.Dispose();
	public Event<delegate void(NumericField)> OnEditEnded ~ _.Dispose();

	public double Value
	{
		get => mValue;
		set
		{
			let clamped = Math.Clamp(value, mMin, mMax);
			if (mValue != clamped)
			{
				mValue = clamped;
				UpdateText();
				OnValueChanged(this, clamped);
			}
		}
	}

	public double Min
	{
		get => mMin;
		set { mMin = value; if (mMax < mMin) mMax = mMin; if (mValue < mMin) Value = mMin; }
	}

	public double Max
	{
		get => mMax;
		set { mMax = value; if (mMin > mMax) mMin = mMax; if (mValue > mMax) Value = mMax; }
	}

	public double Step
	{
		get => mStep;
		set => mStep = Math.Max(0, value);
	}

	public int32 DecimalPlaces
	{
		get => mDecimalPlaces;
		set { mDecimalPlaces = Math.Max(0, value); UpdateText(); }
	}

	public this()
	{
		IsFocusable = true;
		IsTabStop = true;
		Cursor = .IBeam;
		StyleId = new String("edittext");
		mBehavior = new TextEditingBehavior(this);
		// Only allow digits, minus, and decimal point.
		let filter = new InputFilter();
		filter.SetCustomFilter(new (c) => (c >= '0' && c <= '9') || c == '-' || c == '.');
		mBehavior.Filter = filter;
		UpdateText();
	}

	public void Increment() { Value = mValue + mStep; }
	public void Decrement() { Value = mValue - mStep; }

	// === Prefix/Suffix ===

	public void SetPrefix(StringView text)
	{
		delete mPrefixView; mPrefixView = null;
		if (mPrefixText == null) mPrefixText = new String(text);
		else mPrefixText.Set(text);
		Invalidate();
	}

	public void SetPrefix(View view)
	{
		delete mPrefixText; mPrefixText = null;
		delete mPrefixView;
		mPrefixView = view;
		Invalidate();
	}

	public void SetSuffix(StringView text)
	{
		delete mSuffixView; mSuffixView = null;
		if (mSuffixText == null) mSuffixText = new String(text);
		else mSuffixText.Set(text);
		Invalidate();
	}

	public void SetSuffix(View view)
	{
		delete mSuffixText; mSuffixText = null;
		delete mSuffixView;
		mSuffixView = view;
		Invalidate();
	}

	// === ITextEditHost ===

	StringView ITextEditHost.Text => mText;
	int32 ITextEditHost.MaxLength => 0;
	bool ITextEditHost.IsReadOnly => false;
	bool ITextEditHost.IsMultiline => false;

	int32 ITextEditHost.TextCharCount
	{
		get
		{
			int32 count = 0;
			for (let c in mText.DecodedChars) count++;
			return count;
		}
	}

	void ITextEditHost.ReplaceText(int32 charStart, int32 charLength, StringView replacement)
	{
		let byteStart = CharToByteOffset(mText, charStart);
		let byteEnd = CharToByteOffset(mText, charStart + charLength);
		mText.Remove(byteStart, byteEnd - byteStart);
		mText.Insert(byteStart, replacement);
		mGlyphsDirty = true;
	}

	void ITextEditHost.OnTextModified()
	{
		mGlyphsDirty = true;
		mCursorBlinkResetTime = Context?.TotalTime ?? 0;
		Invalidate();

		// Live parse value from text (without reformatting).
		if (!mUpdatingText)
		{
			let text = scope String(mText);
			text.Trim();
			if (double.Parse(text) case .Ok(let parsed))
			{
				let clamped = Math.Clamp(parsed, mMin, mMax);
				if (mValue != clamped)
				{
					mValue = clamped;
					OnValueChanged(this, mValue);
				}
			}
		}
	}

	int32 ITextEditHost.HitTestPosition(float localX, float localY)
	{
		EnsureGlyphsValid();
		if (Context?.FontService == null) return 0;
		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let font = Context.FontService.GetFont(fontSize);
		if (font == null || font.Shaper == null) return 0;
		let hitX = localX - TextPaddingLeft - GetPrefixWidth(fontSize) + mScrollOffsetX;
		let result = font.Shaper.HitTest(font.Font, mGlyphPositions, hitX, 0);
		return result.InsertionIndex;
	}

	float ITextEditHost.GetCursorXPosition(int32 charIndex)
	{
		EnsureGlyphsValid();
		if (Context?.FontService == null) return 0;
		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let font = Context.FontService.GetFont(fontSize);
		if (font == null || font.Shaper == null) return 0;
		return font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, charIndex);
	}

	float ITextEditHost.GetCursorYPosition(int32 charIndex) => 0;

	float ITextEditHost.LineHeight
	{
		get
		{
			let fontSize = ResolveStyleFloat(.FontSize, 14);
			if (Context?.FontService == null) return fontSize;
			let font = Context.FontService.GetFont(fontSize);
			if (font == null) return fontSize;
			return font.Font.Metrics.LineHeight;
		}
	}

	int32 ITextEditHost.HitTestGlyphPosition(float glyphX, float glyphY)
	{
		let fontSize = ResolveStyleFloat(.FontSize, 14);
		return ((ITextEditHost)this).HitTestPosition(glyphX + TextPaddingLeft + GetPrefixWidth(fontSize) - mScrollOffsetX, glyphY);
	}

	IClipboard ITextEditHost.Clipboard => Context?.Clipboard;
	float ITextEditHost.CurrentTime => Context?.TotalTime ?? 0;

	// === Layout ===

	private float TextPaddingLeft => 6;
	private float TextPaddingRight => 6;
	private float EffectiveButtonWidth => ShowSpinButtons ? ButtonWidth : 0;
	private float TextAreaWidth
	{
		get
		{
			let fontSize = ResolveStyleFloat(.FontSize, 14);
			return Width - EffectiveButtonWidth - TextPaddingLeft - TextPaddingRight - GetPrefixWidth(fontSize) - GetSuffixWidth(fontSize);
		}
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let fontSize = ResolveStyleFloat(.FontSize, 14);
		float textH = fontSize;
		if (Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(fontSize);
			if (font != null) textH = font.Font.Metrics.LineHeight;
		}
		let prefixW = GetPrefixWidth(fontSize);
		let suffixW = GetSuffixWidth(fontSize);
		MeasuredSize = .(constraints.ConstrainWidth(80 + EffectiveButtonWidth + prefixW + suffixW), constraints.ConstrainHeight(textH + 8));
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		let fontSize = ResolveStyleFloat(.FontSize, 14);

		// Background.
		let bgDrawable = ResolveStyleDrawable(.Background);
		if (bgDrawable != null)
			bgDrawable.Draw(ctx, bounds, GetControlState());
		else
			ctx.VG.FillRect(bounds, .(30, 32, 42, 255));

		// Spin buttons.
		if (ShowSpinButtons)
			DrawSpinButtons(ctx, fontSize);

		// Focused border overlay.
		if (IsFocused)
		{
			let accentColor = ResolveStyleColor(.AccentColor, ResolveStyleColor(.CursorColor, .(80, 160, 255, 255)));
			if (let rrd = bgDrawable as RoundedRectDrawable)
			{
				if (!rrd.Radii.IsZero)
					ctx.VG.StrokeRoundedRect(bounds, rrd.Radii, accentColor, 2.0f);
				else
					ctx.VG.StrokeRect(bounds, accentColor, 2.0f);
			}
			else
				ctx.VG.StrokeRect(bounds, accentColor, 2.0f);
		}

		// Prefix/suffix and text content.
		let prefixW = GetPrefixWidth(fontSize);
		let suffixW = GetSuffixWidth(fontSize);
		let textAreaX = TextPaddingLeft + prefixW;
		let textAreaW = TextAreaWidth;

		ctx.VG.PushClipRect(.(TextPaddingLeft, 0, Width - TextPaddingLeft - TextPaddingRight - EffectiveButtonWidth, Height));

		// Draw prefix.
		if (prefixW > 0)
			DrawDecoration(ctx, true, TextPaddingLeft, 0, Height, fontSize);

		// Draw suffix.
		if (suffixW > 0)
			DrawDecoration(ctx, false, TextPaddingLeft + prefixW + textAreaW, 0, Height, fontSize);

		// Text, selection, cursor.
		DrawTextContent(ctx, textAreaX, textAreaW, fontSize);

		ctx.VG.PopClip();

		// Repeat timer for held spin buttons.
		if (mPressedButton != 0)
		{
			let dt = 1.0f / 60.0f;
			mRepeatTimer += dt;
			if (mRepeatTimer >= mRepeatDelay)
			{
				if (mPressedButton == 1) Increment();
				else Decrement();
				mRepeatDelay = mRepeatInterval;
			}
		}
	}

	private void DrawSpinButtons(UIDrawContext ctx, float fontSize)
	{
		let btnX = Width - ButtonWidth;
		let halfH = Height * 0.5f;
		let btnBorder = ResolveStyleColor(.BorderColor, .(80, 85, 100, 255));

		// Up button state.
		let upState = (mPressedButton == 1) ? ControlState.Pressed : ((mHoveredButton == 1) ? ControlState.Hover : ControlState.Normal);
		let upDrawable = ResolveStyleDrawable(.SpinUpDrawable);
		if (upDrawable != null)
			upDrawable.Draw(ctx, .(btnX, 0, ButtonWidth, halfH), upState);
		else
		{
			var upBg = Color(50, 55, 68, 255);
			if (mPressedButton == 1) upBg = Palette.ComputePressed(upBg);
			else if (mHoveredButton == 1) upBg = Palette.ComputeHover(upBg);
			ctx.VG.FillRect(.(btnX, 0, ButtonWidth, halfH), upBg);
		}

		// Down button state.
		let downState = (mPressedButton == -1) ? ControlState.Pressed : ((mHoveredButton == -1) ? ControlState.Hover : ControlState.Normal);
		let downDrawable = ResolveStyleDrawable(.SpinDownDrawable);
		if (downDrawable != null)
			downDrawable.Draw(ctx, .(btnX, halfH, ButtonWidth, halfH), downState);
		else
		{
			var downBg = Color(50, 55, 68, 255);
			if (mPressedButton == -1) downBg = Palette.ComputePressed(downBg);
			else if (mHoveredButton == -1) downBg = Palette.ComputeHover(downBg);
			ctx.VG.FillRect(.(btnX, halfH, ButtonWidth, halfH), downBg);
		}

		// Divider lines - use the background drawable's border color for consistency.
		Color sepColor = btnBorder;
		let bgDrawable = ResolveStyleDrawable(.Background);
		if (let rrd = bgDrawable as RoundedRectDrawable)
			sepColor = rrd.BorderColor;
		ctx.VG.FillRect(.(btnX, 1, 1, Height - 2), sepColor);
		ctx.VG.FillRect(.(btnX, halfH, ButtonWidth, 1), sepColor);

		// Arrows.
		let arrowColor = ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
		let arrowSz = Math.Min(ButtonWidth, halfH) * 0.25f;

		// Up arrow - try SVG icon, fallback to VG triangle.
		let upIcon = ResolveStyleDrawable(.ArrowUpIcon);
		let cx = btnX + ButtonWidth * 0.5f;
		if (upIcon != null)
		{
			let iconSize = arrowSz * 2;
			upIcon.Draw(ctx, .(cx - iconSize * 0.5f, halfH * 0.5f - iconSize * 0.5f, iconSize, iconSize));
		}
		else
		{
			let cy = halfH * 0.5f;
			ctx.VG.BeginPath();
			ctx.VG.MoveTo(cx - arrowSz, cy + arrowSz * 0.5f);
			ctx.VG.LineTo(cx + arrowSz, cy + arrowSz * 0.5f);
			ctx.VG.LineTo(cx, cy - arrowSz * 0.5f);
			ctx.VG.ClosePath();
			ctx.VG.Fill(arrowColor);
		}

		// Down arrow.
		let downIcon = ResolveStyleDrawable(.ArrowDownIcon);
		if (downIcon != null)
		{
			let iconSize = arrowSz * 2;
			downIcon.Draw(ctx, .(cx - iconSize * 0.5f, halfH + halfH * 0.5f - iconSize * 0.5f, iconSize, iconSize));
		}
		else
		{
			let cy = halfH + halfH * 0.5f;
			ctx.VG.BeginPath();
			ctx.VG.MoveTo(cx - arrowSz, cy - arrowSz * 0.5f);
			ctx.VG.LineTo(cx + arrowSz, cy - arrowSz * 0.5f);
			ctx.VG.LineTo(cx, cy + arrowSz * 0.5f);
			ctx.VG.ClosePath();
			ctx.VG.Fill(arrowColor);
		}
	}

	private void DrawTextContent(UIDrawContext ctx, float areaX, float areaW, float fontSize)
	{
		if (ctx.FontService == null) return;

		let font = ctx.FontService.GetFont(fontSize);
		if (font == null) return;

		let lineH = font.Font.Metrics.LineHeight;
		let textY = (Height - lineH) * 0.5f;

		EnsureGlyphsValid();
		EnsureCursorVisible(font);

		let textX = areaX - mScrollOffsetX;

		// Selection.
		if (IsFocused && mBehavior.IsSelecting && font.Shaper != null)
		{
			let selColor = ResolveStyleColor(.SelectionColor, .(60, 120, 200, 80));
			let selStart = font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, mBehavior.SelectionStart);
			let selEnd = font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, mBehavior.SelectionEnd);
			ctx.VG.FillRect(.(textX + selStart, textY, selEnd - selStart, lineH), selColor);
		}

		// Text.
		if (mGlyphPositions.Count > 0)
		{
			var textColor = ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
			if (!IsEffectivelyEnabled)
				textColor = Palette.ComputeDisabled(textColor);
			ctx.VG.DrawPositionedGlyphs(mGlyphPositions, font, textX, textY + font.Font.Metrics.Ascent, textColor);
		}

		// Cursor.
		if (IsFocused)
		{
			let elapsed = (Context?.TotalTime ?? 0) - mCursorBlinkResetTime;
			if (((int)(elapsed / 0.5f) % 2) == 0)
			{
				float cursorX = 0;
				if (font.Shaper != null)
					cursorX = font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, mBehavior.CursorPosition);
				let cursorColor = ResolveStyleColor(.CursorColor, .(220, 225, 235, 255));
				ctx.VG.FillRect(.(textX + cursorX - 1, textY, 2, lineH), cursorColor);
			}
		}
	}

	private void DrawDecoration(UIDrawContext ctx, bool isPrefix, float x, float y, float height, float fontSize)
	{
		let decoText = isPrefix ? mPrefixText : mSuffixText;
		let decoView = isPrefix ? mPrefixView : mSuffixView;

		if (decoText != null && !decoText.IsEmpty)
		{
			let font = ctx.FontService?.GetFont(fontSize);
			if (font != null)
			{
				let textColor = ResolveStyleColor(.TextDimColor, ResolveStyleColor(.PlaceholderColor, .(140, 150, 170, 255)));
				let w = font.Font.MeasureString(decoText);
				ctx.VG.DrawText(decoText, font, .(x, y, w, height), .Left, .Middle, textColor);
			}
		}
		else if (decoView != null)
		{
			let pw = decoView.MeasuredSize.X;
			let ph = decoView.MeasuredSize.Y;
			let py = y + (height - ph) * 0.5f;
			// Layout the view so it has Width/Height set for drawing.
			decoView.Layout(x, py, pw, ph);
			ctx.VG.PushState();
			ctx.VG.Translate(x, py);
			decoView.OnDraw(ctx);
			ctx.VG.PopState();
		}
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;

		if (ShowSpinButtons)
		{
			let btnX = Width - ButtonWidth;
			if (e.X >= btnX)
			{
				let halfH = Height * 0.5f;
				if (e.Y < halfH)
				{
					mPressedButton = 1;
					Increment();
				}
				else
				{
					mPressedButton = -1;
					Decrement();
				}
				mRepeatTimer = 0;
				mRepeatDelay = 0.4f;
				Context?.FocusManager.SetCapture(this);
				e.Handled = true;
				return;
			}
		}

		// Text area click.
		if (e.ClickCount <= 1)
		{
			mIsDragging = true;
			Context?.FocusManager.SetCapture(this);
		}
		mBehavior.HandleMouseDown(e.X, e.Y, e.ClickCount, e.Modifiers);
		ResetBlink();
		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (ShowSpinButtons)
		{
			let btnX = Width - ButtonWidth;
			if (e.X >= btnX)
			{
				mHoveredButton = (e.Y < Height * 0.5f) ? 1 : -1;
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
		if (e.Button != .Left) return;

		if (mPressedButton != 0)
		{
			mPressedButton = 0;
			Context?.FocusManager.ReleaseCapture();
			e.Handled = true;
		}
		else if (mIsDragging)
		{
			mIsDragging = false;
			Context?.FocusManager.ReleaseCapture();
			e.Handled = true;
		}
	}

	public override void OnMouseLeave()
	{
		mHoveredButton = 0;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;

		switch (e.Key)
		{
		case .Up:
			Increment();
			e.Handled = true;
		case .Down:
			Decrement();
			e.Handled = true;
		case .PageUp:
			Value = mValue + mStep * 10;
			e.Handled = true;
		case .PageDown:
			Value = mValue - mStep * 10;
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
		if (!IsEffectivelyEnabled) return;
		mBehavior.HandleTextInput(e.Character);
		ResetBlink();
		e.Handled = true;
	}

	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;
		if (IsFocused)
		{
			if (e.DeltaY > 0) Increment();
			else if (e.DeltaY < 0) Decrement();
			e.Handled = true;
		}
	}

	public override void OnFocusGained()
	{
		ResetBlink();
		OnEditBegan(this);
	}

	public override void OnFocusLost()
	{
		mIsDragging = false;
		CommitText();
		OnEditEnded(this);
	}

	// === Internal ===

	private void UpdateText()
	{
		mUpdatingText = true;
		let text = scope String();
		if (mDecimalPlaces == 0)
		{
			text.AppendF("{}", (int64)Math.Round(mValue));
		}
		else
		{
			text.AppendF("{0:F}", mValue);
			let dotIndex = text.IndexOf('.');
			if (dotIndex >= 0)
			{
				let desiredLen = dotIndex + 1 + mDecimalPlaces;
				if (text.Length > desiredLen)
					text.RemoveToEnd(desiredLen);
			}
		}
		mText.Set(text);
		mGlyphsDirty = true;
		mBehavior.Reset();
		let charCount = ((ITextEditHost)this).TextCharCount;
		mBehavior.CursorPosition = charCount;
		mBehavior.AnchorPosition = charCount;
		mUpdatingText = false;
	}

	public void CommitText()
	{
		let text = scope String(mText);
		text.Trim();
		if (double.Parse(text) case .Ok(let parsed))
		{
			let clamped = Math.Clamp(parsed, mMin, mMax);
			mValue = clamped;
			OnValueChanged(this, mValue);
		}
		UpdateText();
	}

	private void ResetBlink()
	{
		mCursorBlinkResetTime = Context?.TotalTime ?? 0;
		Invalidate();
	}

	private void EnsureGlyphsValid()
	{
		if (!mGlyphsDirty) return;
		mGlyphsDirty = false;
		mGlyphPositions.Clear();
		mTextWidth = 0;

		if (Context?.FontService == null) return;
		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let font = Context.FontService.GetFont(fontSize);
		if (font == null) return;

		if (!mText.IsEmpty)
		{
			if (font.Shaper != null)
			{
				if (font.Shaper.ShapeText(font.Font, mText, mGlyphPositions) case .Ok(let w))
					mTextWidth = w;
			}
			else
			{
				mTextWidth = font.Font.MeasureString(mText, mGlyphPositions);
			}
		}
	}

	private void EnsureCursorVisible(CachedFont font)
	{
		if (font?.Shaper == null) return;
		let cursorX = font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, mBehavior.CursorPosition);
		let contentW = TextAreaWidth;

		if (cursorX - mScrollOffsetX < 0)
			mScrollOffsetX = cursorX;
		else if (cursorX - mScrollOffsetX > contentW)
			mScrollOffsetX = cursorX - contentW;

		let maxScroll = Math.Max(0, mTextWidth - contentW);
		mScrollOffsetX = Math.Clamp(mScrollOffsetX, 0, maxScroll);
	}

	private float GetPrefixWidth(float fontSize)
	{
		if (mPrefixText != null && !mPrefixText.IsEmpty)
		{
			if (Context?.FontService != null)
			{
				let font = Context.FontService.GetFont(fontSize);
				if (font != null)
					return font.Font.MeasureString(mPrefixText) + 4;
			}
		}
		else if (mPrefixView != null)
		{
			mPrefixView.Measure(.Loose(200, 200));
			return mPrefixView.MeasuredSize.X + 4;
		}
		return 0;
	}

	private float GetSuffixWidth(float fontSize)
	{
		if (mSuffixText != null && !mSuffixText.IsEmpty)
		{
			if (Context?.FontService != null)
			{
				let font = Context.FontService.GetFont(fontSize);
				if (font != null)
					return font.Font.MeasureString(mSuffixText) + 4;
			}
		}
		else if (mSuffixView != null)
		{
			mSuffixView.Measure(.Loose(200, 200));
			return mSuffixView.MeasuredSize.X + 4;
		}
		return 0;
	}

	private static int32 CharToByteOffset(StringView text, int32 charIndex)
	{
		int32 charCount = 0;
		int32 byteOffset = 0;
		for (let c in text.DecodedChars)
		{
			if (charCount >= charIndex) break;
			charCount++;
			byteOffset = (int32)@c.NextIndex;
		}
		if (charCount < charIndex) return (int32)text.Length;
		return byteOffset;
	}
}
