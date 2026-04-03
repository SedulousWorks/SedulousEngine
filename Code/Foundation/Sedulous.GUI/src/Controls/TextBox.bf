using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Fonts;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A single-line text input control.
public class TextBox : Control
{
	/// Fallback ratio for estimating character width when no font metrics available.
	/// Based on typical monospace font proportions (width ~60% of height).
	private const float FallbackCharWidthRatio = 0.6f;

	// Text editing behavior
	private TextEditingBehavior mEditor = new .() ~ delete _;

	// Placeholder text
	private String mPlaceholder ~ delete _;

	// Font settings
	private float? mFontSize;

	// Text rendering cache
	private List<GlyphPosition> mGlyphPositions = new .() ~ delete _;
	private bool mGlyphPositionsDirty = true;
	private String mCachedText = new .() ~ delete _;

	// Horizontal scroll offset for long text
	private float mScrollOffset = 0;

	// Events
	private EventAccessor<delegate void(TextBox, StringView)> mTextChanged = new .() ~ delete _;

	/// Creates a new TextBox.
	public this()
	{
		// Set text cursor
		Cursor = .Text;

		// Subscribe to editor events
		mEditor.TextChanged.Subscribe(new () => {
			mGlyphPositionsDirty = true;
			InvalidateLayout();
			mTextChanged.[Friend]Invoke(this, mEditor.Text);
		});

		mEditor.SelectionChanged.Subscribe(new () => {
			// Just need to redraw
		});
	}

	/// Creates a new TextBox with initial text.
	public this(StringView text) : this()
	{
		mEditor.SetText(text);
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "TextBox";

	/// The text content.
	public StringView Text
	{
		get => mEditor.Text;
		set
		{
			mEditor.SetText(value);
		}
	}

	/// The placeholder text shown when empty.
	public StringView Placeholder
	{
		get => mPlaceholder ?? "";
		set
		{
			if (mPlaceholder == null)
				mPlaceholder = new String();
			mPlaceholder.Set(value);
		}
	}

	/// Maximum text length (0 = unlimited).
	public int32 MaxLength
	{
		get => mEditor.MaxLength;
		set => mEditor.MaxLength = value;
	}

	/// Whether the text is read-only.
	public bool IsReadOnly
	{
		get => mEditor.IsReadOnly;
		set => mEditor.IsReadOnly = value;
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

	/// Event fired when text changes.
	public EventAccessor<delegate void(TextBox, StringView)> TextChanged => mTextChanged;

	/// Selects all text.
	public void SelectAll()
	{
		mEditor.SelectAll();
	}

	/// Clears all text.
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
		// TextBox has a default padding for the text
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

		// Width is typically set externally, but measure text width as minimum
		float textWidth = 50; // Minimum width
		if (mEditor.Text.Length > 0 && cachedFont != null)
		{
			textWidth = Math.Max(textWidth, cachedFont.Font.MeasureString(mEditor.Text));
		}

		// Return desired size without padding (padding is applied by base class)
		return .(textWidth, lineHeight);
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

		// Update glyph positions if needed
		UpdateGlyphPositions(cachedFont);

		// Calculate text position
		let lineHeight = font.Metrics.LineHeight;
		let textY = bounds.Y + (bounds.Height - lineHeight) / 2;

		// Clip to content bounds
		ctx.PushClipRect(bounds);

		// Calculate scroll offset to keep caret visible
		UpdateScrollOffset(cachedFont, bounds.Width);

		let textX = bounds.X - mScrollOffset;

		// Draw selection highlight
		if (mEditor.HasSelection)
		{
			let selectionColor = Context?.Theme?.SelectionColor ?? Color(100, 149, 237, 100);
			let selection = mEditor.Selection;

			// Get selection rectangles
			let selectionRects = scope List<Rect>();
			if (cachedFont.Shaper != null && mGlyphPositions.Count > 0)
			{
				cachedFont.Shaper.GetSelectionRects(font, mGlyphPositions, selection, lineHeight, selectionRects);
			}
			else
			{
				// Fallback: simple rectangle
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

		// Draw text or placeholder
		if (mEditor.Text.Length > 0)
		{
			let foreground = GetStateForeground();
			let drawBounds = RectangleF(textX, textY, bounds.Width + mScrollOffset, lineHeight);
			ctx.DrawText(mEditor.Text, font, atlas, atlasTexture, drawBounds, .Left, .Top, foreground);
		}
		else if (mPlaceholder != null && mPlaceholder.Length > 0 && !IsFocused)
		{
			// Draw placeholder in secondary text color
			let palette = Context?.Theme?.Palette ?? Palette();
			let placeholderColor = palette.TextSecondary.A > 0
				? Color(palette.TextSecondary.R, palette.TextSecondary.G, palette.TextSecondary.B, 180)
				: Color(GetStateForeground().R / 2, GetStateForeground().G / 2, GetStateForeground().B / 2, 128);
			let drawBounds = RectangleF(textX, textY, bounds.Width + mScrollOffset, lineHeight);
			ctx.DrawText(mPlaceholder, font, atlas, atlasTexture, drawBounds, .Left, .Top, placeholderColor);
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

	private void UpdateGlyphPositions(CachedFont cachedFont)
	{
		if (!mGlyphPositionsDirty && mCachedText == mEditor.Text)
			return;

		mGlyphPositions.Clear();
		mCachedText.Set(mEditor.Text);
		mGlyphPositionsDirty = false;

		if (mEditor.Text.Length == 0)
			return;

		if (cachedFont?.Shaper != null)
		{
			cachedFont.Shaper.ShapeText(cachedFont.Font, mEditor.Text, mGlyphPositions);
		}
	}

	private float GetCaretX(CachedFont cachedFont, int32 charIndex)
	{
		if (cachedFont?.Shaper != null && mGlyphPositions.Count > 0)
		{
			return cachedFont.Shaper.GetCursorPosition(cachedFont.Font, mGlyphPositions, charIndex);
		}

		// Fallback: estimate position using font measurement or approximation
		if (charIndex == 0)
			return 0;

		let text = scope String();
		text.Append(mEditor.Text, 0, Math.Min(charIndex, (int32)mEditor.Text.Length));
		return cachedFont?.Font.MeasureString(text) ?? (charIndex * FontSize * FallbackCharWidthRatio);
	}

	private void UpdateScrollOffset(CachedFont cachedFont, float viewWidth)
	{
		let caretX = GetCaretX(cachedFont, mEditor.CaretPosition);

		// Keep caret visible with some margin
		let margin = 5.0f;

		if (caretX - mScrollOffset < margin)
		{
			// Caret is too far left, scroll left
			mScrollOffset = Math.Max(0, caretX - margin);
		}
		else if (caretX - mScrollOffset > viewWidth - margin)
		{
			// Caret is too far right, scroll right
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

		// Fallback: estimate character index using font measurement or approximation
		if (mEditor.Text.Length == 0)
			return 0;

		// Try to get actual average character width from font
		float charWidth;
		if (cachedFont?.Font != null)
		{
			let totalWidth = cachedFont.Font.MeasureString(mEditor.Text);
			charWidth = totalWidth / mEditor.Text.Length;
		}
		else
		{
			charWidth = FontSize * FallbackCharWidthRatio;
		}

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

		if (mEditor.HandleKeyDown(e.Key, e.Modifiers, Context?.Clipboard, Context?.TotalTime ?? 0))
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
