namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;
using Sedulous.VG;

/// Single-line and multiline text input control. Implements ITextEditHost
/// for TextEditingBehavior. Supports selection, cursor blink, scroll,
/// clipboard, undo/redo, input filtering, prefix/suffix decorations.
public class EditText : View, ITextEditHost
{
	// === Text state ===
	private String mText = new .() ~ delete _;
	public Property<String> Placeholder = new .(null) ~ { if (_.Value != null) delete _.Value; delete _; };
	public Property<bool> IsReadOnly = new .(false) ~ delete _;
	public Property<bool> Multiline = new .(false) ~ delete _;
	public Property<int32> MaxLength = new .(0) ~ delete _;

	// === Glyph cache ===
	protected List<GlyphPosition> mGlyphPositions = new .() ~ delete _;
	private String mCachedDisplayText = new .() ~ delete _;
	protected bool mGlyphsDirty = true;
	private float mTextHeight;
	private float mTextWidth;

	// === Scroll ===
	private float mScrollOffsetX;
	private float mScrollOffsetY;

	// === Cursor blink ===
	protected float mCursorBlinkResetTime;

	// === Drag selection ===
	private bool mIsDragging;

	// === Behavior ===
	protected TextEditingBehavior mBehavior ~ delete _;
	private bool mNeedsCursorScroll;

	// === Prefix/Suffix ===
	private String mPrefixText ~ delete _;
	private View mPrefixView ~ delete _;
	private String mSuffixText ~ delete _;
	private View mSuffixView ~ delete _;

	// === Events ===
	public Event<delegate void(EditText)> OnTextChanged ~ _.Dispose();
	public Event<delegate void(EditText)> OnSubmit ~ _.Dispose();

	// === Properties ===

	public StringView Text
	{
		get => mText;
	}

	public void SetText(StringView text)
	{
		mText.Set(text);
		mGlyphsDirty = true;
		mBehavior.Reset();
		Invalidate();
	}

	public void SetPlaceholder(StringView text)
	{
		if (Placeholder.Value == null) Placeholder.Value = new String(text);
		else Placeholder.Value.Set(text);
	}

	public InputFilter Filter
	{
		get => mBehavior.Filter;
		set => mBehavior.Filter = value;
	}

	/// Whether right-click shows the Cut/Copy/Paste context menu.
	public bool ShowContextMenuOnRightClick = true;

	public int32 CursorPosition => mBehavior.CursorPosition;
	public int32 SelectionStart => mBehavior.SelectionStart;
	public int32 SelectionEnd => mBehavior.SelectionEnd;

	// === Prefix/Suffix ===

	/// Set a text prefix rendered inside the field before the text area.
	public void SetPrefix(StringView text)
	{
		delete mPrefixView; mPrefixView = null;
		if (mPrefixText == null) mPrefixText = new String(text);
		else mPrefixText.Set(text);
		Invalidate();
	}

	/// Set a View prefix (e.g., colored label) rendered inside the field.
	public void SetPrefix(View view)
	{
		delete mPrefixText; mPrefixText = null;
		delete mPrefixView;
		mPrefixView = view;
		Invalidate();
	}

	/// Set a text suffix rendered inside the field after the text area.
	public void SetSuffix(StringView text)
	{
		delete mSuffixView; mSuffixView = null;
		if (mSuffixText == null) mSuffixText = new String(text);
		else mSuffixText.Set(text);
		Invalidate();
	}

	/// Set a View suffix rendered inside the field after the text area.
	public void SetSuffix(View view)
	{
		delete mSuffixText; mSuffixText = null;
		delete mSuffixView;
		mSuffixView = view;
		Invalidate();
	}

	// === Constructor ===

	public this()
	{
		IsFocusable = true;
		IsTabStop = true;
		WantsArrowKeys = true;
		Cursor = .IBeam;
		mBehavior = new TextEditingBehavior(this);

		Placeholder.SetOwner(this, .Visual);
		IsReadOnly.SetOwner(this, .Visual);
		Multiline.SetOwner(this);
		MaxLength.SetOwner(this);

		Multiline.Changed.Add(new (val) => { mGlyphsDirty = true; });
	}

	// === ITextEditHost ===

	StringView ITextEditHost.Text => mText;
	int32 ITextEditHost.MaxLength => MaxLength.Value;
	bool ITextEditHost.IsReadOnly => IsReadOnly.Value;
	bool ITextEditHost.IsMultiline => Multiline.Value;

	int32 ITextEditHost.TextCharCount
	{
		get
		{
			int32 count = 0;
			for (let c in mText.DecodedChars)
				count++;
			return count;
		}
	}

	void ITextEditHost.ReplaceText(int32 charStart, int32 charLength, StringView replacement)
	{
		let byteStart = CharToByteOffset(mText, charStart);
		let byteEnd = CharToByteOffset(mText, charStart + charLength);
		let byteLength = byteEnd - byteStart;

		mText.Remove(byteStart, byteLength);
		mText.Insert(byteStart, replacement);
		mGlyphsDirty = true;
	}

	void ITextEditHost.OnTextModified()
	{
		mGlyphsDirty = true;
		mCursorBlinkResetTime = Context?.TotalTime ?? 0;
		mNeedsCursorScroll = true;
		Invalidate();
		OnTextChanged(this);
	}

	int32 ITextEditHost.HitTestPosition(float localX, float localY)
	{
		EnsureGlyphsValid();

		if (Context?.FontService == null) return 0;
		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let font = Context.FontService.GetFont(ResolveStyleFontFamily(), fontSize);
		if (font == null || font.Shaper == null)
			return FallbackHitTest(localX);

		let padding = ResolveStyleThickness(.Padding, .(6, 4));
		let prefixW = GetPrefixWidth(fontSize);
		let hitX = localX - padding.Left - prefixW + mScrollOffsetX;
		let hitY = localY - padding.Top + mScrollOffsetY;

		if (Multiline.Value)
			return MultilineHitTest(font, hitX, hitY);
		else
		{
			let result = font.Shaper.HitTest(font.Font, mGlyphPositions, hitX, 0);
			return result.InsertionIndex;
		}
	}

	int32 ITextEditHost.HitTestGlyphPosition(float glyphX, float glyphY)
	{
		EnsureGlyphsValid();

		if (Context?.FontService == null) return 0;
		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let font = Context.FontService.GetFont(ResolveStyleFontFamily(), fontSize);
		if (font == null || font.Shaper == null) return 0;

		if (Multiline.Value)
			return MultilineHitTest(font, glyphX, glyphY);
		else
		{
			let result = font.Shaper.HitTest(font.Font, mGlyphPositions, glyphX, 0);
			return result.InsertionIndex;
		}
	}

	/// Multiline hit test that handles empty lines (which have no glyphs).
	private int32 MultilineHitTest(CachedFont font, float hitX, float hitY)
	{
		let lineH = font.Font.Metrics.LineHeight;
		let targetLine = Math.Max(0, (int32)(hitY / lineH));
		let charCount = ((ITextEditHost)this).TextCharCount;

		// Find the char index for the start of this line.
		int32 lineCharStart = GetCharIndexForLine(targetLine);

		// Past end of text (e.g. trailing \n creating an empty last line).
		if (lineCharStart >= charCount)
			return charCount;

		// Check if this line is empty (char at lineCharStart is \n).
		int32 idx = 0;
		for (let c in mCachedDisplayText.DecodedChars)
		{
			if (idx == lineCharStart)
			{
				if (c == '\n')
					return lineCharStart;
				break;
			}
			idx++;
		}

		// For X at or before the start of the line, return line start directly.
		// This avoids shaper edge cases with trailing hits at position 0.
		if (hitX <= 0)
			return lineCharStart;

		// Line has content - use shaper hit test.
		let result = font.Shaper.HitTestWrapped(font.Font, mGlyphPositions, hitX, hitY, lineH);
		return GlyphToCharIndex(result.InsertionIndex, result.IsTrailingHit);
	}

	/// Get the character index at the start of the given line number (0-based).
	private int32 GetCharIndexForLine(int32 line)
	{
		if (line <= 0) return 0;

		int32 currentLine = 0;
		int32 idx = 0;
		for (let c in mCachedDisplayText.DecodedChars)
		{
			if (c == '\n')
			{
				currentLine++;
				if (currentLine == line)
					return idx + 1; // char after the \n
			}
			idx++;
		}
		// Line beyond text - return past end.
		return ((ITextEditHost)this).TextCharCount;
	}

	float ITextEditHost.GetCursorXPosition(int32 charIndex)
	{
		EnsureGlyphsValid();

		if (Context?.FontService == null) return 0;
		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let font = Context.FontService.GetFont(ResolveStyleFontFamily(), fontSize);
		if (font == null || font.Shaper == null) return 0;

		if (!Multiline.Value)
			return font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, charIndex);

		return GetMultilineCursorX(charIndex);
	}

	float ITextEditHost.GetCursorYPosition(int32 charIndex)
	{
		EnsureGlyphsValid();

		if (Context?.FontService == null) return 0;
		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let font = Context.FontService.GetFont(ResolveStyleFontFamily(), fontSize);
		if (font == null) return 0;

		return GetCursorYFromCharIndex(charIndex, font.Font.Metrics.LineHeight);
	}

	float ITextEditHost.LineHeight
	{
		get
		{
			if (Context?.FontService == null) return ResolveStyleFloat(.FontSize, 14);
			let fontSize = ResolveStyleFloat(.FontSize, 14);
			let font = Context.FontService.GetFont(ResolveStyleFontFamily(), fontSize);
			if (font == null) return fontSize;
			return font.Font.Metrics.LineHeight;
		}
	}

	IClipboard ITextEditHost.Clipboard => Context?.Clipboard;
	float ITextEditHost.CurrentTime => Context?.TotalTime ?? 0;

	// === Display text (virtual for PasswordBox) ===

	/// Get the text to display. Override in PasswordBox for masking.
	protected virtual void GetDisplayText(String outText)
	{
		outText.Set(mText);
	}

	// === Measurement ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let padding = ResolveStyleThickness(.Padding, .(6, 4));
		float textH = fontSize;

		if (Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(ResolveStyleFontFamily(), fontSize);
			if (font != null)
			{
				textH = font.Font.Metrics.LineHeight;
				if (Multiline.Value)
					textH *= 3;
			}
		}

		let prefixW = GetPrefixWidth(fontSize);
		let suffixW = GetSuffixWidth(fontSize);
		let minWidth = 100 + prefixW + suffixW + padding.TotalHorizontal;
		let totalH = textH + padding.TotalVertical;

		MeasuredSize = .(constraints.ConstrainWidth(minWidth), constraints.ConstrainHeight(totalH));
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let padding = ResolveStyleThickness(.Padding, .(6, 4));

		// Background drawable from theme.
		let bgDrawable = ResolveStyleDrawable(.Background);
		if (bgDrawable != null)
			bgDrawable.Draw(ctx, bounds, GetControlState());
		else
			ctx.VG.FillRect(bounds, .(30, 32, 42, 255));

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
			{
				let cr = ResolveStyleFloat(.CornerRadius);
				if (cr > 0)
					ctx.VG.StrokeRoundedRect(bounds, cr, accentColor, 2.0f);
				else
					ctx.VG.StrokeRect(bounds, accentColor, 2.0f);
			}
		}

		// Content area.
		let contentX = padding.Left;
		let contentY = padding.Top;
		let contentW = Width - padding.TotalHorizontal;
		let contentH = Height - padding.TotalVertical;

		let prefixW = GetPrefixWidth(fontSize);
		let suffixW = GetSuffixWidth(fontSize);

		// Clip to content.
		ctx.VG.PushClipRect(.(contentX, contentY, contentW, contentH));

		// Draw prefix.
		if (prefixW > 0)
			DrawPrefix(ctx, contentX, contentY, contentH, fontSize);

		// Draw suffix.
		if (suffixW > 0)
			DrawSuffix(ctx, contentX + contentW - suffixW, contentY, contentH, fontSize);

		// Text area (between prefix and suffix).
		let textAreaX = contentX + prefixW;
		let textAreaW = contentW - prefixW - suffixW;

		DrawTextContent(ctx, textAreaX, contentY, textAreaW, contentH, fontSize);

		ctx.VG.PopClip();
	}

	/// Draw the main text content (selection, glyphs, cursor, placeholder).
	protected void DrawTextContent(UIDrawContext ctx, float areaX, float areaY, float areaW, float areaH, float fontSize)
	{
		if (ctx.FontService == null) return;

		let font = ctx.FontService.GetFont(ResolveStyleFontFamily(), fontSize);
		if (font == null) return;

		let lineH = font.Font.Metrics.LineHeight;
		let textY = Multiline.Value
			? (areaY - mScrollOffsetY)
			: (areaY + (areaH - lineH) * 0.5f);

		EnsureGlyphsValid();
		if (mNeedsCursorScroll)
		{
			EnsureCursorVisible(font);
			mNeedsCursorScroll = false;
		}

		let textX = areaX - mScrollOffsetX;

		if (mText.IsEmpty && !IsFocused && Placeholder.Value != null && Placeholder.Value.Length > 0)
		{
			// Draw placeholder.
			let placeholderColor = ResolveStyleColor(.PlaceholderColor, .(140, 150, 170, 255));
			ctx.VG.DrawText(Placeholder.Value, font,
				.(areaX, areaY, areaW, areaH),
				.Left, Multiline.Value ? .Top : .Middle, placeholderColor);
		}
		else
		{
			// Draw selection highlight.
			if (IsFocused && mBehavior.IsSelecting && font.Shaper != null)
			{
				let selColor = ResolveStyleColor(.SelectionColor, .(60, 120, 200, 80));

				if (Multiline.Value)
				{
					let glyphStart = CharToGlyphIndex(mBehavior.SelectionStart);
					let glyphEnd = CharToGlyphIndex(mBehavior.SelectionEnd);
					let selRange = Sedulous.Fonts.SelectionRange(glyphStart, glyphEnd);
					let rects = scope List<Sedulous.Fonts.Rect>();
					font.Shaper.GetSelectionRects(font.Font, mGlyphPositions, selRange, lineH, rects);
					for (let r in rects)
						ctx.VG.FillRect(.(textX + r.X, textY + r.Y, r.Width, r.Height), selColor);
				}
				else
				{
					let selStart = font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, mBehavior.SelectionStart);
					let selEnd = font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, mBehavior.SelectionEnd);
					ctx.VG.FillRect(.(textX + selStart, textY, selEnd - selStart, lineH), selColor);
				}
			}

			// Draw text glyphs.
			if (mGlyphPositions.Count > 0)
			{
				var textColor = ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
				if (!IsEffectivelyEnabled)
					textColor = Palette.ComputeDisabled(textColor);
				ctx.VG.DrawPositionedGlyphs(mGlyphPositions, font,
					textX, textY + font.Font.Metrics.Ascent, textColor);
			}
		}

		// Draw cursor (blinking).
		if (IsFocused && !IsReadOnly.Value)
		{
			let elapsed = (Context?.TotalTime ?? 0) - mCursorBlinkResetTime;
			let cursorVisible = ((int)(elapsed / 0.5f) % 2) == 0;
			if (cursorVisible)
			{
				float cursorX = 0;
				if (font.Shaper != null)
				{
					if (Multiline.Value)
						cursorX = GetMultilineCursorX(mBehavior.CursorPosition);
					else
						cursorX = font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, mBehavior.CursorPosition);
				}
				let cursorY = Multiline.Value ? GetCursorYFromCharIndex(mBehavior.CursorPosition, lineH) : 0;
				let cursorColor = ResolveStyleColor(.CursorColor, .(220, 225, 235, 255));
				ctx.VG.FillRect(.(textX + cursorX - 1, textY + cursorY, 2, lineH), cursorColor);
			}
		}
	}

	// === Input handlers ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;

		if (e.Button == .Right && ShowContextMenuOnRightClick)
		{
			ShowContextMenu(e.X, e.Y);
			e.Handled = true;
			return;
		}

		if (e.Button != .Left) return;

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
		if (mIsDragging)
		{
			mBehavior.HandleMouseMove(e.X, e.Y);
			ResetBlink();
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (e.Button != .Left) return;

		if (mIsDragging)
		{
			mIsDragging = false;
			Context?.FocusManager.ReleaseCapture();
			e.Handled = true;
		}
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;

		// Enter -> submit for single-line, newline for multiline (handled by behavior).
		if (e.Key == .Return && !Multiline.Value)
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
		if (!IsEffectivelyEnabled) return;

		mBehavior.HandleTextInput(e.Character);
		ResetBlink();
		e.Handled = true;
	}

	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		if (!Multiline.Value) return;

		let padding = ResolveStyleThickness(.Padding, .(6, 4));
		let contentHeight = Height - padding.TotalVertical;
		let maxScrollY = Math.Max(0, mTextHeight - contentHeight);
		if (maxScrollY <= 0) return;

		let lineH = ((ITextEditHost)this).LineHeight;
		mScrollOffsetY = Math.Clamp(mScrollOffsetY - e.DeltaY * lineH * 3, 0, maxScrollY);
		Invalidate();
		e.Handled = true;
	}

	public override void OnFocusGained()
	{
		ResetBlink();
	}

	public override void OnFocusLost()
	{
		mIsDragging = false;
	}

	// === Glyph shaping ===

	protected void EnsureGlyphsValid()
	{
		if (!mGlyphsDirty) return;

		mGlyphsDirty = false;
		mGlyphPositions.Clear();
		mTextWidth = 0;
		mTextHeight = 0;

		if (Context?.FontService == null) return;

		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let font = Context.FontService.GetFont(ResolveStyleFontFamily(), fontSize);
		if (font == null) return;

		mCachedDisplayText.Clear();
		GetDisplayText(mCachedDisplayText);

		if (!mCachedDisplayText.IsEmpty)
		{
			if (Multiline.Value && font.Shaper != null)
			{
				let padding = ResolveStyleThickness(.Padding, .(6, 4));
				let prefixW = GetPrefixWidth(fontSize);
				let suffixW = GetSuffixWidth(fontSize);
				let contentWidth = Width - padding.TotalHorizontal - prefixW - suffixW;
				float totalH = 0;
				if (font.Shaper.ShapeTextWrapped(font.Font, mCachedDisplayText, contentWidth, mGlyphPositions, out totalH) case .Ok)
				{
					mTextHeight = totalH;
					for (let gp in mGlyphPositions)
					{
						let right = gp.X + gp.Advance;
						if (right > mTextWidth) mTextWidth = right;
					}
				}
			}
			else if (font.Shaper != null)
			{
				if (font.Shaper.ShapeText(font.Font, mCachedDisplayText, mGlyphPositions) case .Ok(let w))
					mTextWidth = w;
				mTextHeight = font.Font.Metrics.LineHeight;
			}
			else
			{
				mTextWidth = font.Font.MeasureString(mCachedDisplayText, mGlyphPositions);
				mTextHeight = font.Font.Metrics.LineHeight;
			}
		}
	}

	// === Scroll management ===

	private void EnsureCursorVisible(CachedFont font)
	{
		if (font?.Shaper == null) return;

		let cursorX = Multiline.Value
			? GetMultilineCursorX(mBehavior.CursorPosition)
			: font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, mBehavior.CursorPosition);

		let fontSize = ResolveStyleFloat(.FontSize, 14);
		let padding = ResolveStyleThickness(.Padding, .(6, 4));
		let prefixW = GetPrefixWidth(fontSize);
		let suffixW = GetSuffixWidth(fontSize);
		let contentWidth = Width - padding.TotalHorizontal - prefixW - suffixW;

		// Horizontal scroll.
		if (!Multiline.Value)
		{
			if (cursorX - mScrollOffsetX < 0)
				mScrollOffsetX = cursorX;
			else if (cursorX - mScrollOffsetX > contentWidth)
				mScrollOffsetX = cursorX - contentWidth;

			let maxScroll = Math.Max(0, mTextWidth - contentWidth);
			mScrollOffsetX = Math.Clamp(mScrollOffsetX, 0, maxScroll);
		}

		// Vertical scroll (multiline).
		if (Multiline.Value)
		{
			let lineH = font.Font.Metrics.LineHeight;
			let contentHeight = Height - padding.TotalVertical;
			let cursorY = ((ITextEditHost)this).GetCursorYPosition(mBehavior.CursorPosition);

			if (cursorY - mScrollOffsetY < 0)
				mScrollOffsetY = cursorY;
			else if (cursorY + lineH - mScrollOffsetY > contentHeight)
				mScrollOffsetY = cursorY + lineH - contentHeight;

			let maxScrollY = Math.Max(0, mTextHeight - contentHeight);
			mScrollOffsetY = Math.Clamp(mScrollOffsetY, 0, maxScrollY);
		}
	}

	// === Prefix/Suffix helpers ===

	/// Get the pixel width of the prefix content.
	protected float GetPrefixWidth(float fontSize)
	{
		if (mPrefixText != null && !mPrefixText.IsEmpty)
		{
			if (Context?.FontService != null)
			{
				let font = Context.FontService.GetFont(ResolveStyleFontFamily(), fontSize);
				if (font != null)
					return font.Font.MeasureString(mPrefixText) + 4; // 4px spacing after prefix
			}
		}
		else if (mPrefixView != null)
		{
			mPrefixView.Measure(.Loose(200, 200));
			return mPrefixView.MeasuredSize.X + 4;
		}
		return 0;
	}

	/// Get the pixel width of the suffix content.
	protected float GetSuffixWidth(float fontSize)
	{
		if (mSuffixText != null && !mSuffixText.IsEmpty)
		{
			if (Context?.FontService != null)
			{
				let font = Context.FontService.GetFont(ResolveStyleFontFamily(), fontSize);
				if (font != null)
					return font.Font.MeasureString(mSuffixText) + 4; // 4px spacing before suffix
			}
		}
		else if (mSuffixView != null)
		{
			mSuffixView.Measure(.Loose(200, 200));
			return mSuffixView.MeasuredSize.X + 4;
		}
		return 0;
	}

	/// Draw the prefix text or view.
	private void DrawPrefix(UIDrawContext ctx, float x, float y, float height, float fontSize)
	{
		if (mPrefixText != null && !mPrefixText.IsEmpty)
		{
			let font = ctx.FontService?.GetFont(ResolveStyleFontFamily(), fontSize);
			if (font != null)
			{
				let textColor = ResolveStyleColor(.TextDimColor, ResolveStyleColor(.PlaceholderColor, .(140, 150, 170, 255)));
				ctx.VG.DrawText(mPrefixText, font, .(x, y, GetPrefixWidth(fontSize) - 4, height), .Left, .Middle, textColor);
			}
		}
		else if (mPrefixView != null)
		{
			let pw = mPrefixView.MeasuredSize.X;
			let ph = mPrefixView.MeasuredSize.Y;
			let py = y + (height - ph) * 0.5f;
			mPrefixView.Layout(x, py, pw, ph);
			ctx.VG.PushState();
			ctx.VG.Translate(x, py);
			mPrefixView.OnDraw(ctx);
			ctx.VG.PopState();
		}
	}

	/// Draw the suffix text or view.
	private void DrawSuffix(UIDrawContext ctx, float x, float y, float height, float fontSize)
	{
		if (mSuffixText != null && !mSuffixText.IsEmpty)
		{
			let font = ctx.FontService?.GetFont(ResolveStyleFontFamily(), fontSize);
			if (font != null)
			{
				let textColor = ResolveStyleColor(.TextDimColor, ResolveStyleColor(.PlaceholderColor, .(140, 150, 170, 255)));
				ctx.VG.DrawText(mSuffixText, font, .(x + 4, y, GetSuffixWidth(fontSize) - 4, height), .Left, .Middle, textColor);
			}
		}
		else if (mSuffixView != null)
		{
			let pw = mSuffixView.MeasuredSize.X;
			let ph = mSuffixView.MeasuredSize.Y;
			let py = y + (height - ph) * 0.5f;
			mSuffixView.Layout(x + 4, py, pw, ph);
			ctx.VG.PushState();
			ctx.VG.Translate(x + 4, py);
			mSuffixView.OnDraw(ctx);
			ctx.VG.PopState();
		}
	}

	// === Context menu ===

	/// Show right-click context menu with Cut/Copy/Paste/Select All.
	private void ShowContextMenu(float localX, float localY)
	{
		if (Context == null) return;

		let menu = new ContextMenu();

		if (!IsReadOnly.Value)
		{
			delegate void() cutAction = new () => { mBehavior.HandleKeyDown(.X, .Ctrl); };
			menu.AddItem("Cut", cutAction, mBehavior.IsSelecting);
		}

		delegate void() copyAction = new () => { mBehavior.HandleKeyDown(.C, .Ctrl); };
		menu.AddItem("Copy", copyAction, mBehavior.IsSelecting);

		if (!IsReadOnly.Value)
		{
			let hasClipText = Context.Clipboard != null && Context.Clipboard.HasText;
			delegate void() pasteAction = new () => { mBehavior.HandleKeyDown(.V, .Ctrl); };
			menu.AddItem("Paste", pasteAction, hasClipText);
		}

		menu.AddSeparator();
		delegate void() selectAllAction = new () => { mBehavior.HandleKeyDown(.A, .Ctrl); };
		menu.AddItem("Select All", selectAllAction);

		let screenPos = LocalToScreen(.(localX, localY));
		menu.Show(Context, screenPos.X, screenPos.Y);
	}

	// === Helpers ===

	private void ResetBlink()
	{
		mCursorBlinkResetTime = Context?.TotalTime ?? 0;
		mNeedsCursorScroll = true;
		Invalidate();
	}

	/// Compute the X position of the cursor in multiline mode.
	private float GetMultilineCursorX(int32 charIndex)
	{
		if (mGlyphPositions.Count == 0) return 0;

		// Check if charIndex is at or right after a newline.
		if (charIndex > 0)
		{
			int32 idx = 0;
			for (let c in mCachedDisplayText.DecodedChars)
			{
				if (idx == charIndex - 1)
				{
					if (c == '\n') return 0;
					break;
				}
				idx++;
			}
		}

		if (charIndex == 0) return 0;

		// Find the glyph at this char index.
		for (int32 i = 0; i < mGlyphPositions.Count; i++)
		{
			if (mGlyphPositions[i].StringIndex == charIndex)
				return mGlyphPositions[i].X;
			if (mGlyphPositions[i].StringIndex > charIndex)
			{
				if (i > 0)
				{
					let prev = mGlyphPositions[i - 1];
					if (mGlyphPositions[i].Y != prev.Y)
						return prev.X + prev.Advance;
				}
				return 0;
			}
		}

		let last = mGlyphPositions[mGlyphPositions.Count - 1];
		return last.X + last.Advance;
	}

	/// Convert glyph insertion index back to text character index.
	private int32 GlyphToCharIndex(int32 glyphInsertionIndex, bool isTrailingHit = false)
	{
		if (mGlyphPositions.Count == 0)
			return 0;
		if (glyphInsertionIndex <= 0)
			return mGlyphPositions[0].StringIndex;
		if (glyphInsertionIndex >= mGlyphPositions.Count)
		{
			let lastGlyph = mGlyphPositions[mGlyphPositions.Count - 1];
			return lastGlyph.StringIndex + 1;
		}

		// The insertion point is between glyph[idx-1] and glyph[idx].
		let prevGlyph = mGlyphPositions[glyphInsertionIndex - 1];
		let nextGlyph = mGlyphPositions[glyphInsertionIndex];

		// If glyphs are on different lines and there's a gap (skipped newline),
		// use trailing flag to decide: trailing = end of current line,
		// non-trailing = start of next line.
		if (nextGlyph.Y != prevGlyph.Y && nextGlyph.StringIndex > prevGlyph.StringIndex + 1)
		{
			if (isTrailingHit)
				return prevGlyph.StringIndex + 1; // after last char on current line (the \n)
			else
				return nextGlyph.StringIndex; // start of next line
		}

		return prevGlyph.StringIndex + 1;
	}

	/// Convert text character index to glyph index.
	private int32 CharToGlyphIndex(int32 charIndex)
	{
		for (int32 i = 0; i < mGlyphPositions.Count; i++)
		{
			if (mGlyphPositions[i].StringIndex >= charIndex)
				return i;
		}
		return (int32)mGlyphPositions.Count;
	}

	/// Get the Y position for a cursor at the given char index.
	private float GetCursorYFromCharIndex(int32 charIndex, float lineHeight)
	{
		int32 line = 0;
		int32 idx = 0;
		let text = mCachedDisplayText;
		for (let c in text.DecodedChars)
		{
			if (idx >= charIndex) break;
			if (c == '\n') line++;
			idx++;
		}
		return line * lineHeight;
	}

	/// Fallback hit-test when no shaper is available.
	private int32 FallbackHitTest(float localX)
	{
		let padding = ResolveStyleThickness(.Padding, .(6, 4));
		let hitX = localX - padding.Left + mScrollOffsetX;
		let charCount = ((ITextEditHost)this).TextCharCount;
		if (charCount == 0 || mTextWidth <= 0) return 0;
		let avgCharW = mTextWidth / charCount;
		return Math.Clamp((int32)(hitX / avgCharW + 0.5f), 0, charCount);
	}

	/// Convert a character index to a byte offset in a UTF-8 string.
	protected static int32 CharToByteOffset(StringView text, int32 charIndex)
	{
		int32 charCount = 0;
		int32 byteOffset = 0;

		for (let c in text.DecodedChars)
		{
			if (charCount >= charIndex) break;
			charCount++;
			byteOffset = (int32)@c.NextIndex;
		}

		if (charCount < charIndex)
			return (int32)text.Length;

		return byteOffset;
	}

	public override void OnActivate()
	{
		OnSubmit(this);
	}
}
