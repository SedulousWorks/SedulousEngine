namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;

/// Numeric input field with integrated up/down spin buttons.
/// Self-contained: owns its own TextEditingBehavior for text editing,
/// draws a unified border with spin buttons inside.
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
	public float ButtonWidth = 20;
	private float? mFontSize;

	// === Spin button state ===
	private int8 mHoveredButton; // 0=none, 1=up, -1=down
	private int8 mPressedButton;
	private float mRepeatTimer;
	private float mRepeatDelay = 0.4f;
	private float mRepeatInterval = 0.05f;

	public Event<delegate void(NumericField, double)> OnValueChanged ~ _.Dispose();

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

	public float FontSize
	{
		get => mFontSize ?? Context?.Theme?.GetDimension("EditText.FontSize", 14) ?? 14;
		set { mFontSize = value; mGlyphsDirty = true; InvalidateLayout(); }
	}

	public this()
	{
		IsFocusable = true;
		Cursor = .IBeam;
		mBehavior = new TextEditingBehavior(this);
		// Only allow digits, minus, and decimal point.
		let filter = new InputFilter();
		filter.SetCustomFilter(new (c) => (c >= '0' && c <= '9') || c == '-' || c == '.');
		mBehavior.Filter = filter;
		UpdateText();
	}

	public void Increment() { Value = mValue + mStep; }
	public void Decrement() { Value = mValue - mStep; }

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
		InvalidateVisual();

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
		let font = Context.FontService.GetFont(FontSize);
		if (font == null || font.Shaper == null) return 0;
		let hitX = localX - TextPaddingLeft + mScrollOffsetX;
		let result = font.Shaper.HitTest(font.Font, mGlyphPositions, hitX, 0);
		return result.InsertionIndex;
	}

	float ITextEditHost.GetCursorXPosition(int32 charIndex)
	{
		EnsureGlyphsValid();
		if (Context?.FontService == null) return 0;
		let font = Context.FontService.GetFont(FontSize);
		if (font == null || font.Shaper == null) return 0;
		return font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, charIndex);
	}

	float ITextEditHost.GetCursorYPosition(int32 charIndex) => 0;
	float ITextEditHost.LineHeight => FontSize;

	int32 ITextEditHost.HitTestGlyphPosition(float glyphX, float glyphY)
	{
		return ((ITextEditHost)this).HitTestPosition(glyphX + TextPaddingLeft - mScrollOffsetX, glyphY);
	}

	IClipboard ITextEditHost.Clipboard => Context?.Clipboard;
	float ITextEditHost.CurrentTime => Context?.TotalTime ?? 0;

	// === Layout constants ===

	private float TextPaddingLeft => 6;
	private float TextPaddingRight => 6;
	private float TextAreaWidth => Width - ButtonWidth - TextPaddingLeft - TextPaddingRight;

	// === Measurement ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float textH = FontSize;
		if (Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(FontSize);
			if (font != null) textH = font.Font.Metrics.LineHeight;
		}
		MeasuredSize = .(wSpec.Resolve(80 + ButtonWidth), hSpec.Resolve(textH + 8));
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		let radius = ctx.Theme?.GetDimension("EditText.CornerRadius", 4) ?? 4;
		let btnX = Width - ButtonWidth;
		let halfH = Height * 0.5f;

		// Unified background.
		if (!ctx.TryDrawDrawable("EditText.Background", bounds, GetControlState()))
		{
			let bgColor = ctx.Theme?.GetColor("EditText.Background", .(30, 32, 42, 255)) ?? .(30, 32, 42, 255);
			ctx.VG.FillRoundedRect(bounds, radius, bgColor);
		}

		// Spin button backgrounds.
		let btnBg = ctx.Theme?.GetColor("NumericField.ButtonBackground", .(50, 55, 68, 255)) ?? .(50, 55, 68, 255);
		let btnBorder = ctx.Theme?.GetColor("NumericField.ButtonBorder", .(80, 85, 100, 255)) ?? .(80, 85, 100, 255);

		// Up button.
		let upState = (mPressedButton == 1) ? ControlState.Pressed : ((mHoveredButton == 1) ? ControlState.Hover : ControlState.Normal);
		let upRect = RectangleF(btnX, 0, ButtonWidth, halfH);
		if (!ctx.TryDrawDrawable("NumericField.UpButton", upRect, upState))
		{
			var upBg = btnBg;
			if (mPressedButton == 1) upBg = Palette.ComputePressed(btnBg);
			else if (mHoveredButton == 1) upBg = Palette.ComputeHover(btnBg);
			ctx.VG.FillRect(upRect, upBg);
		}

		// Down button.
		let downState = (mPressedButton == -1) ? ControlState.Pressed : ((mHoveredButton == -1) ? ControlState.Hover : ControlState.Normal);
		let downRect = RectangleF(btnX, halfH, ButtonWidth, halfH);
		if (!ctx.TryDrawDrawable("NumericField.DownButton", downRect, downState))
		{
			var downBg = btnBg;
			if (mPressedButton == -1) downBg = Palette.ComputePressed(btnBg);
			else if (mHoveredButton == -1) downBg = Palette.ComputeHover(btnBg);
			ctx.VG.FillRect(downRect, downBg);
		}

		// Button separators.
		ctx.VG.FillRect(.(btnX, 0, 1, Height), btnBorder);
		ctx.VG.FillRect(.(btnX, halfH, ButtonWidth, 1), btnBorder);

		// Arrows.
		let arrowColor = ctx.Theme?.Palette.Text ?? .(220, 225, 235, 255);
		let arrowSz = Math.Min(ButtonWidth, halfH) * 0.25f;

		// Up arrow.
		{
			let cx = btnX + ButtonWidth * 0.5f;
			let cy = halfH * 0.5f;
			let upArrowRect = RectangleF(cx - arrowSz, cy - arrowSz, arrowSz * 2, arrowSz * 2);
			if (!ctx.TryDrawDrawable("NumericField.UpArrow", upArrowRect, .Normal))
			{
				ctx.VG.BeginPath();
				ctx.VG.MoveTo(cx - arrowSz, cy + arrowSz * 0.5f);
				ctx.VG.LineTo(cx + arrowSz, cy + arrowSz * 0.5f);
				ctx.VG.LineTo(cx, cy - arrowSz * 0.5f);
				ctx.VG.ClosePath();
				ctx.VG.Fill(arrowColor);
			}
		}

		// Down arrow.
		{
			let cx = btnX + ButtonWidth * 0.5f;
			let cy = halfH + halfH * 0.5f;
			let downArrowRect = RectangleF(cx - arrowSz, cy - arrowSz, arrowSz * 2, arrowSz * 2);
			if (!ctx.TryDrawDrawable("NumericField.DownArrow", downArrowRect, .Normal))
			{
				ctx.VG.BeginPath();
				ctx.VG.MoveTo(cx - arrowSz, cy - arrowSz * 0.5f);
				ctx.VG.LineTo(cx + arrowSz, cy - arrowSz * 0.5f);
				ctx.VG.LineTo(cx, cy + arrowSz * 0.5f);
				ctx.VG.ClosePath();
				ctx.VG.Fill(arrowColor);
			}
		}

		// Unified border.
		let focused = IsFocused;
		let borderColor = focused
			? (ctx.Theme?.TryGetColor("EditText.Border.Focused") ?? ctx.Theme?.Palette.PrimaryAccent ?? .(80, 160, 255, 255))
			: (ctx.Theme?.GetColor("EditText.Border", .(80, 85, 100, 255)) ?? .(80, 85, 100, 255));
		let borderWidth = focused ? 2.0f : 1.0f;
		ctx.VG.StrokeRoundedRect(bounds, radius, borderColor, borderWidth);

		// Text area - clip to text region.
		let textAreaX = TextPaddingLeft;
		let textAreaW = TextAreaWidth;
		ctx.PushClip(.(textAreaX, 0, textAreaW, Height));

		if (ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(FontSize);
			if (font != null)
			{
				let lineH = font.Font.Metrics.LineHeight;
				let textY = (Height - lineH) * 0.5f;

				EnsureGlyphsValid();
				EnsureCursorVisible(font);

				let textX = textAreaX - mScrollOffsetX;

				// Selection highlight.
				if (focused && mBehavior.IsSelecting && font.Shaper != null)
				{
					let selColor = ctx.Theme?.GetColor("EditText.Selection", .(60, 120, 200, 100)) ?? .(60, 120, 200, 100);
					let selStart = font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, mBehavior.SelectionStart);
					let selEnd = font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, mBehavior.SelectionEnd);
					ctx.VG.FillRect(.(textX + selStart, textY, selEnd - selStart, lineH), selColor);
				}

				// Text.
				if (mGlyphPositions.Count > 0)
				{
					let textColor = ctx.Theme?.GetColor("EditText.Foreground") ?? ctx.Theme?.Palette.Text ?? .(220, 225, 235, 255);
					ctx.VG.DrawPositionedGlyphs(mGlyphPositions, font, textX, textY + font.Font.Metrics.Ascent, textColor);
				}

				// Cursor.
				if (focused)
				{
					let elapsed = (Context?.TotalTime ?? 0) - mCursorBlinkResetTime;
					if (((int)(elapsed / 0.5f) % 2) == 0)
					{
						float cursorX = 0;
						if (font.Shaper != null)
							cursorX = font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, mBehavior.CursorPosition);
						let cursorColor = ctx.Theme?.GetColor("EditText.Cursor") ?? ctx.Theme?.Palette.Text ?? .(220, 225, 235, 255);
						ctx.VG.FillRect(.(textX + cursorX - 1, textY, 2, lineH), cursorColor);
					}
				}
			}
		}

		ctx.PopClip();

		// Repeat timer for held spin buttons.
		if (mPressedButton != 0)
		{
			let dt = 1.0f / 60.0f;
			mRepeatTimer += dt;
			if (mRepeatTimer >= mRepeatDelay)
			{
				if (mPressedButton == 1) Increment();
				else Decrement();
				mRepeatDelay = mRepeatInterval; // switch to fast repeat
			}
		}
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;

		let btnX = Width - ButtonWidth;
		if (e.X >= btnX)
		{
			// Spin button click.
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
		}
		else
		{
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
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		// Update spin button hover state.
		let btnX = Width - ButtonWidth;
		if (e.X >= btnX)
		{
			mHoveredButton = (e.Y < Height * 0.5f) ? 1 : -1;
		}
		else
		{
			mHoveredButton = 0;
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

	public override void OnFocusGained() { ResetBlink(); }

	public override void OnFocusLost()
	{
		mIsDragging = false;
		CommitText();
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
		// Place cursor at end.
		let charCount = ((ITextEditHost)this).TextCharCount;
		mBehavior.CursorPosition = charCount;
		mBehavior.AnchorPosition = charCount;
		mUpdatingText = false;
	}

	private void CommitText()
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
	}

	private void EnsureGlyphsValid()
	{
		if (!mGlyphsDirty) return;
		mGlyphsDirty = false;
		mGlyphPositions.Clear();
		mTextWidth = 0;

		if (Context?.FontService == null) return;
		let font = Context.FontService.GetFont(FontSize);
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
