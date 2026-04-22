using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Fonts;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A single-line password input control that masks characters.
public class PasswordBox : Control
{
	/// Fallback ratio for estimating character width when no font metrics available.
	private const float FallbackCharWidthRatio = 0.6f;

	// Text editing behavior
	private TextEditingBehavior mEditor = new .() ~ delete _;

	// Password masking
	private char32 mPasswordChar = '*'; // Asterisk (universal font support)

	// Font settings
	private float? mFontSize;

	// Text rendering cache for masked text
	private List<GlyphPosition> mGlyphPositions = new .() ~ delete _;
	private bool mGlyphPositionsDirty = true;
	private String mMaskedText = new .() ~ delete _;

	// Horizontal scroll offset
	private float mScrollOffset = 0;

	// Events
	private EventAccessor<delegate void(PasswordBox)> mPasswordChanged = new .() ~ delete _;

	/// Creates a new PasswordBox.
	public this()
	{
		// Set text cursor
		Cursor = .Text;

		// Subscribe to editor events
		mEditor.TextChanged.Subscribe(new () => {
			mGlyphPositionsDirty = true;
			InvalidateLayout();
			mPasswordChanged.[Friend]Invoke(this);
		});

		mEditor.SelectionChanged.Subscribe(new () => {
			// Just need to redraw
		});
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "PasswordBox";

	/// The password content (actual characters).
	public StringView Password
	{
		get => mEditor.Text;
		set => mEditor.SetText(value);
	}

	/// The character used to mask the password.
	public char32 PasswordChar
	{
		get => mPasswordChar;
		set
		{
			if (mPasswordChar != value)
			{
				mPasswordChar = value;
				mGlyphPositionsDirty = true;
			}
		}
	}

	/// Maximum password length (0 = unlimited).
	public int32 MaxLength
	{
		get => mEditor.MaxLength;
		set => mEditor.MaxLength = value;
	}

	/// The font size. If null, uses the theme's default font size.
	public float FontSize
	{
		get => mFontSize ?? Context?.Theme?.DefaultFontSize ?? 14f;
		set
		{
			if (mFontSize != value)
			{
				mFontSize = value;
				mGlyphPositionsDirty = true;
				InvalidateLayout();
			}
		}
	}

	/// Event fired when password changes.
	public EventAccessor<delegate void(PasswordBox)> PasswordChanged => mPasswordChanged;

	/// Selects all text.
	public void SelectAll()
	{
		mEditor.SelectAll();
	}

	/// Clears the password.
	public void Clear()
	{
		mEditor.SetText("");
	}

	// === Font Service ===

	private IFontService GetFontService()
	{
		if (Context != null)
		{
			if (Context.GetService<IFontService>() case .Ok(let service))
				return service;
		}
		return null;
	}

	private CachedFont GetCachedFont()
	{
		let fontService = GetFontService();
		if (fontService == null)
			return null;
		return fontService.GetFont(FontSize);
	}

	// === Layout ===

	protected override Thickness GetEffectivePadding()
	{
		let style = GetThemeStyle();
		if (style.Padding != default)
			return style.Padding;
		return .(6, 4, 6, 4);
	}

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		let fontSize = FontSize;
		let cachedFont = GetCachedFont();
		let lineHeight = cachedFont?.Font.Metrics.LineHeight ?? (fontSize * 1.2f);

		float textWidth = 50; // Minimum width
		return .(textWidth, lineHeight);
	}

	// === Masked Text ===

	private void UpdateMaskedText()
	{
		mMaskedText.Clear();
		let len = mEditor.Text.Length;
		for (int i = 0; i < len; i++)
		{
			// Count actual characters, not bytes (skip UTF-8 continuation bytes)
			if (i < len && ((uint8)mEditor.Text[i] & 0xC0) != 0x80)
				mMaskedText.Append(mPasswordChar);
		}
	}

	private void UpdateGlyphPositions(CachedFont cachedFont)
	{
		if (!mGlyphPositionsDirty)
			return;

		UpdateMaskedText();
		mGlyphPositions.Clear();
		mGlyphPositionsDirty = false;

		if (mMaskedText.Length == 0)
			return;

		if (cachedFont?.Shaper != null)
		{
			cachedFont.Shaper.ShapeText(cachedFont.Font, mMaskedText, mGlyphPositions);
		}
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		// Draw background and border
		RenderBackground(ctx);

		let bounds = ContentBounds;
		let fontService = GetFontService();
		let cachedFont = GetCachedFont();

		if (fontService == null || cachedFont == null)
			return;

		let font = cachedFont.Font;
		let atlas = cachedFont.Atlas;
		let atlasTexture = fontService.GetAtlasTexture(cachedFont);

		if (atlas == null || atlasTexture == null)
			return;

		// Update glyph positions
		UpdateGlyphPositions(cachedFont);

		// Calculate text position
		let lineHeight = font.Metrics.LineHeight;
		let textY = bounds.Y + (bounds.Height - lineHeight) / 2;

		// Clip to content bounds
		ctx.PushClipRect(bounds);

		// Calculate scroll offset
		UpdateScrollOffset(cachedFont, bounds.Width);

		let textX = bounds.X - mScrollOffset;

		// Draw selection highlight
		if (mEditor.HasSelection)
		{
			let selectionColor = Context?.Theme?.SelectionColor ?? Color(100, 149, 237, 100);
			let selection = mEditor.Selection;

			// Get selection rectangles based on masked text positions
			let selectionRects = scope List<Rect>();
			if (cachedFont.Shaper != null && mGlyphPositions.Count > 0)
			{
				cachedFont.Shaper.GetSelectionRects(font, mGlyphPositions, selection, lineHeight, selectionRects);
			}
			else
			{
				let startX = GetCaretX(cachedFont, selection.Start);
				let endX = GetCaretX(cachedFont, selection.End);
				selectionRects.Add(.(startX, 0, endX - startX, lineHeight));
			}

			for (let rect in selectionRects)
			{
				let drawRect = RectangleF(textX + rect.X, textY + rect.Y, rect.Width, rect.Height);
				ctx.FillRect(drawRect, selectionColor);
			}
		}

		// Draw masked text
		if (mMaskedText.Length > 0)
		{
			let foreground = GetStateForeground();
			let drawBounds = RectangleF(textX, textY, bounds.Width + mScrollOffset, lineHeight);
			ctx.DrawText(mMaskedText, font, atlas, atlasTexture, drawBounds, .Left, .Top, foreground);
		}

		// Draw caret when focused
		if (IsFocused && mEditor.IsCaretVisible(Context?.TotalTime ?? 0))
		{
			let caretX = textX + GetCaretX(cachedFont, mEditor.CaretPosition);
			let caretRect = RectangleF(caretX, textY, 1.5f, lineHeight);
			ctx.FillRect(caretRect, GetStateForeground());
		}

		ctx.PopClip();
	}

	private float GetCaretX(CachedFont cachedFont, int32 charIndex)
	{
		if (cachedFont?.Shaper != null && mGlyphPositions.Count > 0)
		{
			return cachedFont.Shaper.GetCursorPosition(cachedFont.Font, mGlyphPositions, charIndex);
		}

		// Fallback: estimate using masked char width (measure single char or use fallback ratio)
		let charWidth = cachedFont?.Font.MeasureString(".") ?? (FontSize * FallbackCharWidthRatio);
		return charIndex * charWidth;
	}

	private void UpdateScrollOffset(CachedFont cachedFont, float viewWidth)
	{
		let caretX = GetCaretX(cachedFont, mEditor.CaretPosition);
		let margin = 5.0f;

		if (caretX - mScrollOffset < margin)
		{
			mScrollOffset = Math.Max(0, caretX - margin);
		}
		else if (caretX - mScrollOffset > viewWidth - margin)
		{
			mScrollOffset = caretX - viewWidth + margin;
		}
	}

	private int32 HitTestCharIndex(float localX)
	{
		let cachedFont = GetCachedFont();
		if (cachedFont == null)
			return 0;

		let bounds = ContentBounds;
		let x = localX - bounds.X + mScrollOffset;

		if (cachedFont.Shaper != null && mGlyphPositions.Count > 0)
		{
			let result = cachedFont.Shaper.HitTest(cachedFont.Font, mGlyphPositions, x, 0);
			return result.InsertionIndex;
		}

		// Fallback: estimate character index using masked char width
		let charWidth = cachedFont?.Font.MeasureString(".") ?? (FontSize * FallbackCharWidthRatio);
		let index = (int32)(x / charWidth);
		return (int32)Math.Clamp(index, 0, mEditor.Text.Length);
	}

	// === Input Handling ===

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button == .Left && IsEffectivelyEnabled)
		{
			let charIndex = HitTestCharIndex(e.LocalX);
			let extend = e.HasModifier(.Shift);

			if (e.ClickCount >= 3)
			{
				mEditor.HandleTripleClick();
			}
			else if (e.ClickCount == 2)
			{
				mEditor.HandleDoubleClick(charIndex);
			}
			else
			{
				mEditor.HandleClick(charIndex, extend);
			}

			// Capture mouse for drag selection
			Context?.FocusManager?.SetCapture(this);
			mEditor.ResetCaretBlink(Context?.TotalTime ?? 0);
		}
	}

	protected override void OnMouseMove(MouseEventArgs e)
	{
		base.OnMouseMove(e);

		// Check if we have capture (for drag selection)
		if (Context?.FocusManager?.CapturedElement == this)
		{
			let charIndex = HitTestCharIndex(e.LocalX);
			mEditor.HandleDrag(charIndex);
		}
	}

	protected override void OnMouseUp(MouseButtonEventArgs e)
	{
		base.OnMouseUp(e);

		if (e.Button == .Left)
		{
			// Release capture
			if (Context?.FocusManager?.CapturedElement == this)
				Context?.FocusManager?.ReleaseCapture();
		}
	}

	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);

		let ctrl = e.HasModifier(.Ctrl);

		// Block copy and cut for security
		if (ctrl && (e.Key == .C || e.Key == .X))
		{
			e.Handled = true;
			return;
		}

		// Use null clipboard to prevent copy/cut
		if (mEditor.HandleKeyDown(e.Key, e.Modifiers, e.Key == .V ? Context?.Clipboard : null, Context?.TotalTime ?? 0))
		{
			e.Handled = true;
			mEditor.ResetCaretBlink(Context?.TotalTime ?? 0);
		}
	}

	protected override void OnTextInput(TextInputEventArgs e)
	{
		base.OnTextInput(e);

		if (mEditor.HandleTextInput(e.Character, Context?.TotalTime ?? 0))
		{
			e.Handled = true;
			mEditor.ResetCaretBlink(Context?.TotalTime ?? 0);
		}
	}

	protected override void OnGotFocus(FocusEventArgs e)
	{
		base.OnGotFocus(e);
		mEditor.ResetCaretBlink(Context?.TotalTime ?? 0);
	}

	protected override void OnLostFocus(FocusEventArgs e)
	{
		base.OnLostFocus(e);
		mEditor.ClearSelection();
		// Release capture if we have it
		if (Context?.FocusManager?.CapturedElement == this)
			Context?.FocusManager?.ReleaseCapture();
	}
}
