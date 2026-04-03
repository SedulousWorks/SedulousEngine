using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Fonts;

namespace Sedulous.GUI;

/// Displays text with optional wrapping and alignment.
/// TextBlock is a leaf control that cannot have children.
public class TextBlock : Control
{
	/// Fallback ratio for estimating character width when no font metrics available.
	/// Based on typical proportional font characteristics (width ~60% of height).
	private const float FallbackCharWidthRatio = 0.6f;
	/// Fallback ratio for line height when no font metrics available.
	private const float FallbackLineHeightRatio = 1.2f;

	private String mText ~ delete _;
	private Sedulous.Fonts.TextAlignment mTextAlignment = .Left;
	private TextWrapping mTextWrapping = .NoWrap;
	private TextTrimming mTextTrimming = .None;
	private float? mFontSize;

	// Text measurement cache
	private float mCachedTextWidth = -1;
	private float mCachedLineHeight = -1;
	private float mCachedFontSize = -1;
	private int mCachedTextVersion = -1;
	private int mTextVersion = 0;

	/// Creates a new TextBlock.
	public this()
	{
		// TextBlock is not focusable by default
		IsFocusable = false;
		IsTabStop = false;
	}

	/// Creates a new TextBlock with the specified text.
	public this(StringView text) : this()
	{
		Text = text;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "TextBlock";

	/// The text to display.
	public StringView Text
	{
		get => mText ?? "";
		set
		{
			if (mText == null)
				mText = new String();
			mText.Set(value);
			mTextVersion++;  // Invalidate measurement cache
			InvalidateLayout();
		}
	}

	/// How to align text horizontally.
	public Sedulous.Fonts.TextAlignment TextAlignment
	{
		get => mTextAlignment;
		set
		{
			if (mTextAlignment != value)
			{
				mTextAlignment = value;
				InvalidateLayout();
			}
		}
	}

	/// How to wrap text when it exceeds available width.
	public TextWrapping TextWrapping
	{
		get => mTextWrapping;
		set
		{
			if (mTextWrapping != value)
			{
				mTextWrapping = value;
				InvalidateLayout();
			}
		}
	}

	/// How to trim text when it exceeds available width.
	public TextTrimming TextTrimming
	{
		get => mTextTrimming;
		set
		{
			if (mTextTrimming != value)
			{
				mTextTrimming = value;
				InvalidateLayout();
			}
		}
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
				InvalidateLayout();
			}
		}
	}

	public void Set(StringView text)
	{
		this.Text = text;
	}

	/// Gets the font service from the context.
	private IFontService GetFontService()
	{
		if (Context != null)
		{
			if (Context.GetService<IFontService>() case .Ok(let service))
				return service;
		}
		return null;
	}

	/// Gets the cached font for this control's font settings.
	private CachedFont GetCachedFont()
	{
		let fontService = GetFontService();
		if (fontService == null)
			return null;

		return fontService.GetFont(FontSize);
	}

	/// Measures the text content.
	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		if (mText == null || mText.Length == 0)
			return .Zero;

		let fontSize = FontSize;
		float textWidth, lineHeight;

		// Check if we can use cached measurement
		if (mCachedTextVersion == mTextVersion && mCachedFontSize == fontSize && mCachedTextWidth >= 0)
		{
			textWidth = mCachedTextWidth;
			lineHeight = mCachedLineHeight;
		}
		else
		{
			// Try to measure with actual font
			let cachedFont = GetCachedFont();
			if (cachedFont != null)
			{
				let font = cachedFont.Font;
				textWidth = font.MeasureString(mText);
				lineHeight = font.Metrics.LineHeight;
			}
			else
			{
				// Fallback measurement when no font available
				let charWidth = fontSize * FallbackCharWidthRatio;
				textWidth = mText.Length * charWidth;
				lineHeight = fontSize * FallbackLineHeightRatio;
			}

			// Update cache
			mCachedTextWidth = textWidth;
			mCachedLineHeight = lineHeight;
			mCachedFontSize = fontSize;
			mCachedTextVersion = mTextVersion;
		}

		if (mTextWrapping == .NoWrap)
		{
			return .(textWidth, lineHeight);
		}
		else
		{
			// Wrapped text - calculate based on available width
			let maxWidth = constraints.MaxWidth;
			if (maxWidth == SizeConstraints.Infinity || maxWidth <= 0)
			{
				return .(textWidth, lineHeight);
			}

			// Use shaper for accurate wrapped measurement if available
			let cachedFont = GetCachedFont();
			if (cachedFont?.Shaper != null)
			{
				let positions = scope List<GlyphPosition>();
				float totalHeight = 0;
				if (cachedFont.Shaper.ShapeTextWrapped(cachedFont.Font, mText, maxWidth, positions, out totalHeight) case .Ok)
				{
					return .(Math.Min(textWidth, maxWidth), totalHeight);
				}
			}

			// Fallback: approximate wrapping calculation
			let lineCount = Math.Max(1, (int)Math.Ceiling(textWidth / maxWidth));
			let width = Math.Min(textWidth, maxWidth);
			let height = lineCount * lineHeight;
			return .(width, height);
		}
	}

	/// Renders the text.
	protected override void RenderOverride(DrawContext ctx)
	{
		// Draw background first (from Control)
		RenderBackground(ctx);

		if (mText == null || mText.Length == 0)
			return;

		let foreground = GetStateForeground();
		let bounds = ContentBounds;

		// Try to render with actual font
		let fontService = GetFontService();
		let cachedFont = GetCachedFont();

		if (fontService != null && cachedFont != null)
		{
			let font = cachedFont.Font;
			let atlas = cachedFont.Atlas;
			let atlasTexture = fontService.GetAtlasTexture(cachedFont);

			if (atlas != null && atlasTexture != null)
			{
				// Use wrapped rendering if wrapping is enabled and shaper is available
				if (mTextWrapping != .NoWrap && cachedFont.Shaper != null)
				{
					ctx.DrawTextWrapped(mText, cachedFont, atlasTexture, bounds, bounds.Width, foreground);
				}
				else
				{
					ctx.DrawText(mText, font, atlas, atlasTexture, bounds, mTextAlignment, .Middle, foreground);
				}
				return;
			}
		}

		// Debug fallback - draw a rectangle to show where text would be
		#if DEBUG
		if (Context?.DebugSettings.ShowLayoutBounds ?? false)
		{
			let fontSize = FontSize;
			let textWidth = mText.Length * fontSize * FallbackCharWidthRatio;
			let textHeight = fontSize * FallbackLineHeightRatio;
			var x = bounds.X;
			if (mTextAlignment == .Center)
				x = bounds.X + (bounds.Width - textWidth) / 2;
			else if (mTextAlignment == .Right)
				x = bounds.Right - textWidth;
			ctx.FillRect(.(x, bounds.Y, textWidth, textHeight), Color(foreground.R, foreground.G, foreground.B, 40));
		}
		#endif
	}

}
