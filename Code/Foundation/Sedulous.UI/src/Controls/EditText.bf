namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;
using Sedulous.VG;

/// Single-line text input control. Implements ITextEditHost for
/// TextEditingBehavior. Supports selection, cursor blink, scroll,
/// clipboard, undo/redo, input filtering, and right-click context menu.
public class EditText : View, ITextEditHost
{
	// === Text state ===
	private String mText = new .() ~ delete _;
	private String mPlaceholder ~ delete _;
	private bool mReadOnly;
	private bool mMultiline;
	private int32 mMaxLength;

	// === Glyph cache ===
	private List<GlyphPosition> mGlyphPositions = new .() ~ delete _;
	private String mCachedDisplayText = new .() ~ delete _;
	private bool mGlyphsDirty = true;
	private float mTextHeight;
	private float mTextWidth;

	// === Scroll ===
	private float mScrollOffsetX;
	private float mScrollOffsetY;

	// === Cursor blink ===
	private float mCursorBlinkResetTime;

	// === Drag selection ===
	private bool mIsDragging;

	// === Behavior ===
	protected TextEditingBehavior mBehavior ~ delete _;

	// === Theme overrides ===
	private Color? mTextColor;
	private float? mFontSize;
	private Thickness? mPadding;

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
		InvalidateLayout();
	}

	public StringView Placeholder
	{
		get => (mPlaceholder != null) ? mPlaceholder : "";
	}

	public void SetPlaceholder(StringView text)
	{
		if (mPlaceholder == null) mPlaceholder = new String(text);
		else mPlaceholder.Set(text);
	}

	public bool IsReadOnly
	{
		get => mReadOnly;
		set => mReadOnly = value;
	}

	public bool Multiline
	{
		get => mMultiline;
		set { mMultiline = value; mGlyphsDirty = true; InvalidateLayout(); }
	}

	public int32 MaxLength
	{
		get => mMaxLength;
		set => mMaxLength = value;
	}

	public InputFilter Filter
	{
		get => mBehavior.Filter;
		set => mBehavior.Filter = value;
	}

	public Color TextColor
	{
		get => mTextColor ?? Context?.Theme?.GetColor("EditText.Foreground") ?? .(220, 225, 235, 255);
		set => mTextColor = value;
	}

	public float FontSize
	{
		get => mFontSize ?? Context?.Theme?.GetDimension("EditText.FontSize", 14) ?? 14;
		set { mFontSize = value; mGlyphsDirty = true; InvalidateLayout(); }
	}

	public Thickness Padding
	{
		get => mPadding ?? Context?.Theme?.GetPadding("EditText.Padding", .(6, 4)) ?? .(6, 4);
		set { mPadding = value; InvalidateLayout(); }
	}

	public int32 CursorPosition => mBehavior.CursorPosition;
	public int32 SelectionStart => mBehavior.SelectionStart;
	public int32 SelectionEnd => mBehavior.SelectionEnd;

	// === Constructor ===

	public this()
	{
		IsFocusable = true;
		Cursor = .IBeam;
		// Don't set ClipsContent — the parent's rectangular clip would
		// cut off the rounded border corners. EditText clips its own
		// content area internally via PushClip in OnDraw.
		mBehavior = new TextEditingBehavior(this);
	}

	// === ITextEditHost ===

	StringView ITextEditHost.Text => mText;
	int32 ITextEditHost.MaxLength => mMaxLength;
	bool ITextEditHost.IsReadOnly => mReadOnly;
	bool ITextEditHost.IsMultiline => mMultiline;

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
		InvalidateVisual();
		OnTextChanged(this);
	}

	int32 ITextEditHost.HitTestPosition(float localX, float localY)
	{
		EnsureGlyphsValid();

		if (Context?.FontService == null) return 0;
		let font = Context.FontService.GetFont(FontSize);
		if (font == null || font.Shaper == null)
			return FallbackHitTest(localX);

		let padding = Padding;
		let hitX = localX - padding.Left + mScrollOffsetX;
		let hitY = localY - padding.Top + mScrollOffsetY;

		HitTestResult result;
		if (mMultiline)
		{
			result = font.Shaper.HitTestWrapped(font.Font, mGlyphPositions, hitX, hitY, font.Font.Metrics.LineHeight);
			// Convert glyph-based InsertionIndex back to char index via StringIndex.
			return GlyphToCharIndex(result.InsertionIndex);
		}
		else
		{
			result = font.Shaper.HitTest(font.Font, mGlyphPositions, hitX, 0);
			return result.InsertionIndex;
		}
	}

	int32 ITextEditHost.HitTestGlyphPosition(float glyphX, float glyphY)
	{
		EnsureGlyphsValid();

		if (Context?.FontService == null) return 0;
		let font = Context.FontService.GetFont(FontSize);
		if (font == null || font.Shaper == null) return 0;

		HitTestResult result;
		if (mMultiline)
		{
			result = font.Shaper.HitTestWrapped(font.Font, mGlyphPositions, glyphX, glyphY, font.Font.Metrics.LineHeight);
			return GlyphToCharIndex(result.InsertionIndex);
		}
		else
		{
			result = font.Shaper.HitTest(font.Font, mGlyphPositions, glyphX, 0);
			return result.InsertionIndex;
		}
	}

	float ITextEditHost.GetCursorXPosition(int32 charIndex)
	{
		EnsureGlyphsValid();

		if (Context?.FontService == null) return 0;
		let font = Context.FontService.GetFont(FontSize);
		if (font == null || font.Shaper == null) return 0;

		if (!mMultiline)
			return font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, charIndex);

		// Multiline: compute X from glyph data, handling newlines.
		return GetMultilineCursorX(charIndex);
	}

	/// Compute the X position of the cursor in multiline mode.
	/// Handles newline chars (which have no glyphs) correctly.
	private float GetMultilineCursorX(int32 charIndex)
	{
		if (mGlyphPositions.Count == 0) return 0;

		// Check if charIndex is at or right after a newline -> X = 0 (start of line).
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
				// charIndex is between glyphs (at a newline) — return 0 for line start,
				// or the end of the previous glyph if on the same line.
				if (i > 0)
				{
					let prev = mGlyphPositions[i - 1];
					// If the next glyph is on a different line, cursor is at end of prev line.
					if (mGlyphPositions[i].Y != prev.Y)
						return prev.X + prev.Advance;
				}
				return 0;
			}
		}

		// Past all glyphs — cursor at end of last glyph.
		let last = mGlyphPositions[mGlyphPositions.Count - 1];
		return last.X + last.Advance;
	}

	float ITextEditHost.GetCursorYPosition(int32 charIndex)
	{
		EnsureGlyphsValid();

		if (Context?.FontService == null) return 0;
		let font = Context.FontService.GetFont(FontSize);
		if (font == null) return 0;

		return GetCursorYFromCharIndex(charIndex, font.Font.Metrics.LineHeight);
	}

	float ITextEditHost.LineHeight
	{
		get
		{
			if (Context?.FontService == null) return FontSize;
			let font = Context.FontService.GetFont(FontSize);
			if (font == null) return FontSize;
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

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		let fontSize = FontSize;
		let padding = Padding;
		float textH = fontSize;

		if (Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(fontSize);
			if (font != null)
			{
				textH = font.Font.Metrics.LineHeight;
				if (mMultiline)
					textH *= 3; // default 3 lines for multiline
			}
		}

		MeasuredSize = .(wSpec.Resolve(100 + padding.TotalHorizontal),
						 hSpec.Resolve(textH + padding.TotalVertical));
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		let padding = Padding;
		let radius = ctx.Theme?.GetDimension("EditText.CornerRadius", 4) ?? 4;

		// Background.
		if (!ctx.TryDrawDrawable("EditText.Background", bounds, GetControlState()))
		{
			let bgColor = ctx.Theme?.GetColor("EditText.Background", .(30, 32, 42, 255)) ?? .(30, 32, 42, 255);
			ctx.VG.FillRoundedRect(bounds, radius, bgColor);
		}

		// Border — thicker + accent when focused.
		let borderColor = IsFocused
			? (ctx.Theme?.TryGetColor("EditText.Border.Focused") ?? ctx.Theme?.Palette.PrimaryAccent ?? .(80, 160, 255, 255))
			: (ctx.Theme?.GetColor("EditText.Border", .(80, 85, 100, 255)) ?? .(80, 85, 100, 255));
		let borderWidth = IsFocused ? 2.0f : 1.0f;
		ctx.VG.StrokeRoundedRect(bounds, radius, borderColor, borderWidth);

		// Content area.
		let contentX = padding.Left;
		let contentY = padding.Top;
		let contentW = Width - padding.TotalHorizontal;
		let contentH = Height - padding.TotalVertical;

		// Clip to content.
		ctx.PushClip(.(contentX, contentY, contentW, contentH));

		if (ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(FontSize);
			if (font != null)
			{
				let lineH = font.Font.Metrics.LineHeight;
				// Single-line: vertically centered. Multiline: top-aligned.
				let textY = mMultiline
					? (contentY - mScrollOffsetY)
					: (contentY + (contentH - lineH) * 0.5f);

				EnsureGlyphsValid();
				EnsureCursorVisible(font);

				let textX = contentX - mScrollOffsetX;

				if (mText.IsEmpty && !IsFocused && mPlaceholder != null && mPlaceholder.Length > 0)
				{
					// Draw placeholder.
					let placeholderColor = ctx.Theme?.GetColor("EditText.Placeholder") ?? ctx.Theme?.Palette.TextDim ?? .(140, 150, 170, 255);
					ctx.VG.DrawText(mPlaceholder, font,
						.(contentX, contentY, contentW, lineH),
						.Left, mMultiline ? .Top : .Middle, placeholderColor);
				}
				else
				{
					// Draw selection highlight.
					if (IsFocused && mBehavior.IsSelecting && font.Shaper != null)
					{
						let selColor = ctx.Theme?.GetColor("EditText.Selection", .(60, 120, 200, 100)) ?? .(60, 120, 200, 100);

						if (mMultiline)
						{
							// Multi-line selection: convert char indices to glyph indices for shaper.
							let glyphStart = CharToGlyphIndex(mBehavior.SelectionStart);
							let glyphEnd = CharToGlyphIndex(mBehavior.SelectionEnd);
							let selRange = Sedulous.Fonts.SelectionRange(glyphStart, glyphEnd);
							let rects = scope System.Collections.List<Sedulous.Fonts.Rect>();
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
						let textColor = IsEffectivelyEnabled ? TextColor : Palette.ComputeDisabled(TextColor);
						ctx.VG.DrawPositionedGlyphs(mGlyphPositions, font,
							textX, textY + font.Font.Metrics.Ascent, textColor);
					}
				}

				// Draw cursor (blinking).
				if (IsFocused && !mReadOnly)
				{
					let elapsed = (Context?.TotalTime ?? 0) - mCursorBlinkResetTime;
					let cursorVisible = ((int)(elapsed / 0.5f) % 2) == 0;
					if (cursorVisible)
					{
						float cursorX = 0;
						if (font.Shaper != null)
						{
							if (mMultiline)
								cursorX = GetMultilineCursorX(mBehavior.CursorPosition);
							else
								cursorX = font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, mBehavior.CursorPosition);
						}
						let cursorY = mMultiline ? GetCursorYFromCharIndex(mBehavior.CursorPosition, lineH) : 0;
						let cursorColor = ctx.Theme?.GetColor("EditText.Cursor") ?? ctx.Theme?.Palette.Text ?? .(220, 225, 235, 255);
						ctx.VG.FillRect(.(textX + cursorX - 1, textY + cursorY, 2, lineH), cursorColor);
					}
				}
			}
		}

		ctx.PopClip();
	}

	// === Input handlers ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;

		if (e.Button == .Right)
		{
			ShowContextMenu(e.X, e.Y);
			e.Handled = true;
			return;
		}

		if (e.Button != .Left) return;

		// Only start drag on single click — double/triple click selects
		// word/all and shouldn't be overridden by drag movement.
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

		// Enter -> submit for single-line, newline for multiline.
		// Multiline Enter is handled by TextEditingBehavior.
		if (e.Key == .Return && !mMultiline)
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

	public override void OnFocusGained()
	{
		ResetBlink();
	}

	public override void OnFocusLost()
	{
		mIsDragging = false;
	}

	// === Glyph shaping ===

	private void EnsureGlyphsValid()
	{
		if (!mGlyphsDirty) return;

		mGlyphsDirty = false;
		mGlyphPositions.Clear();
		mTextWidth = 0;
		mTextHeight = 0;

		if (Context?.FontService == null) return;

		let font = Context.FontService.GetFont(FontSize);
		if (font == null) return;

		mCachedDisplayText.Clear();
		GetDisplayText(mCachedDisplayText);

		if (!mCachedDisplayText.IsEmpty)
		{
			if (mMultiline && font.Shaper != null)
			{
				let contentWidth = Width - Padding.TotalHorizontal;
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

		let cursorX = mMultiline
			? GetMultilineCursorX(mBehavior.CursorPosition)
			: font.Shaper.GetCursorPosition(font.Font, mGlyphPositions, mBehavior.CursorPosition);
		let contentWidth = Width - Padding.TotalHorizontal;

		// Horizontal scroll (single-line or if content wider than viewport).
		if (!mMultiline)
		{
			if (cursorX - mScrollOffsetX < 0)
				mScrollOffsetX = cursorX;
			else if (cursorX - mScrollOffsetX > contentWidth)
				mScrollOffsetX = cursorX - contentWidth;

			let maxScroll = Math.Max(0, mTextWidth - contentWidth);
			mScrollOffsetX = Math.Clamp(mScrollOffsetX, 0, maxScroll);
		}

		// Vertical scroll (multiline).
		if (mMultiline)
		{
			let lineH = font.Font.Metrics.LineHeight;
			let contentHeight = Height - Padding.TotalVertical;
			let cursorY = ((ITextEditHost)this).GetCursorYPosition(mBehavior.CursorPosition);

			if (cursorY - mScrollOffsetY < 0)
				mScrollOffsetY = cursorY;
			else if (cursorY + lineH - mScrollOffsetY > contentHeight)
				mScrollOffsetY = cursorY + lineH - contentHeight;

			let maxScrollY = Math.Max(0, mTextHeight - contentHeight);
			mScrollOffsetY = Math.Clamp(mScrollOffsetY, 0, maxScrollY);
		}
	}

	// === Helpers ===

	private void ResetBlink()
	{
		mCursorBlinkResetTime = Context?.TotalTime ?? 0;
	}

	/// Convert a glyph insertion index back to a text character index.
	/// A glyph insertion index N means "cursor between glyph N-1 and glyph N".
	/// Uses GlyphPosition.StringIndex to map back, accounting for skipped
	/// newline characters between glyphs.
	private int32 GlyphToCharIndex(int32 glyphInsertionIndex)
	{
		if (mGlyphPositions.Count == 0)
			return 0;
		if (glyphInsertionIndex <= 0)
			return mGlyphPositions[0].StringIndex;
		if (glyphInsertionIndex >= mGlyphPositions.Count)
		{
			// After last glyph — return one past the last glyph's char index.
			let lastGlyph = mGlyphPositions[mGlyphPositions.Count - 1];
			return lastGlyph.StringIndex + 1;
		}

		// The insertion point is between glyph[idx-1] and glyph[idx].
		// Return the StringIndex of glyph[idx-1] + 1, which lands on
		// the char right after it (could be a \n that was skipped).
		let prevGlyph = mGlyphPositions[glyphInsertionIndex - 1];
		return prevGlyph.StringIndex + 1;
	}

	/// Convert a text character index to a glyph index in mGlyphPositions.
	/// Newlines and other non-rendered chars are skipped by the shaper,
	/// so glyph indices differ from char indices when text contains newlines.
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
	/// Handles positions on empty lines (between consecutive newlines)
	/// by scanning the text for newlines.
	private float GetCursorYFromCharIndex(int32 charIndex, float lineHeight)
	{
		// Count newlines before charIndex to determine the line.
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
	/// Estimates position using average character width.
	private int32 FallbackHitTest(float localX)
	{
		let padding = Padding;
		let hitX = localX - padding.Left + mScrollOffsetX;
		let charCount = ((ITextEditHost)this).TextCharCount;
		if (charCount == 0 || mTextWidth <= 0) return 0;
		let avgCharW = mTextWidth / charCount;
		return Math.Clamp((int32)(hitX / avgCharW + 0.5f), 0, charCount);
	}

	/// Show a context menu with Cut/Copy/Paste/Select All.
	/// Focus is saved/restored automatically by PopupLayer via FocusManager's
	/// focus stack (PushFocus on open, PopFocus on close).
	private void ShowContextMenu(float localX, float localY)
	{
		if (Context == null) return;

		let menu = new ContextMenu();

		if (!mReadOnly)
		{
			menu.AddItem("Cut", new [&]() => {
				mBehavior.HandleKeyDown(.X, .Ctrl);
			}, enabled: mBehavior.IsSelecting);
		}

		menu.AddItem("Copy", new [&]() => {
			mBehavior.HandleKeyDown(.C, .Ctrl);
		}, enabled: mBehavior.IsSelecting);

		if (!mReadOnly)
		{
			let hasClipText = Context.Clipboard != null && Context.Clipboard.HasText;
			menu.AddItem("Paste", new [&]() => {
				mBehavior.HandleKeyDown(.V, .Ctrl);
			}, enabled: hasClipText);
		}

		menu.AddSeparator();
		menu.AddItem("Select All", new [&]() => {
			mBehavior.HandleKeyDown(.A, .Ctrl);
		});

		// Convert local coords to screen coords.
		float screenX = localX + Bounds.X;
		float screenY = localY + Bounds.Y;
		var v = Parent;
		while (v != null)
		{
			screenX += v.Bounds.X;
			screenY += v.Bounds.Y;
			v = v.Parent;
		}

		menu.Show(Context, screenX, screenY);
	}

	/// Convert a character index to a byte offset in a UTF-8 string.
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

		if (charCount < charIndex)
			return (int32)text.Length;

		return byteOffset;
	}
}
