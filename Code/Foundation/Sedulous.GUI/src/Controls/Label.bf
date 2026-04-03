using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Fonts;

namespace Sedulous.GUI;

/// A label that displays text and can be associated with a target control.
/// When clicked, the label focuses its target control.
/// Label can display either text (via ContentText) or a UIElement (via Content).
public class Label : ContentControl
{
	/// Fallback ratio for estimating character width when no font metrics available.
	private const float FallbackCharWidthRatio = 0.6f;
	/// Fallback ratio for line height when no font metrics available.
	private const float FallbackLineHeightRatio = 1.2f;

	private String mContentText ~ delete _;
	private ElementHandle<UIElement> mTarget;
	private float? mFontSize;

	// Text measurement cache
	private float mCachedTextWidth = -1;
	private float mCachedLineHeight = -1;
	private float mCachedFontSize = -1;
	private int mCachedTextVersion = -1;
	private int mTextVersion = 0;

	/// Creates a new Label.
	public this()
	{
		// Labels are not focusable by default
		IsFocusable = false;
		IsTabStop = false;
	}

	/// Creates a new Label with the specified text.
	public this(StringView text) : this()
	{
		ContentText = text;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "Label";

	/// The text to display when no UIElement content is set.
	public StringView ContentText
	{
		get => mContentText ?? "";
		set
		{
			if (mContentText == null)
				mContentText = new String();
			mContentText.Set(value);
			mTextVersion++;  // Invalidate measurement cache
			InvalidateLayout();
		}
	}

	/// The target control to focus when this label is clicked.
	public UIElement Target
	{
		get => mTarget.TryResolve();
		set => mTarget = value;
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

	/// Measures the label content.
	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// If we have UIElement content, use ContentControl's measurement
		if (HasContent)
			return base.MeasureOverride(constraints);

		// Otherwise measure text
		if (mContentText == null || mContentText.Length == 0)
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
				textWidth = font.MeasureString(mContentText);
				lineHeight = font.Metrics.LineHeight;
			}
			else
			{
				// Fallback measurement when no font available
				let charWidth = fontSize * FallbackCharWidthRatio;
				textWidth = mContentText.Length * charWidth;
				lineHeight = fontSize * FallbackLineHeightRatio;
			}

			// Update cache
			mCachedTextWidth = textWidth;
			mCachedLineHeight = lineHeight;
			mCachedFontSize = fontSize;
			mCachedTextVersion = mTextVersion;
		}

		return .(textWidth, lineHeight);
	}

	/// Renders the label content.
	protected override void RenderOverride(DrawContext ctx)
	{
		// Draw background first
		RenderBackground(ctx);

		// If we have UIElement content, render it
		if (HasContent)
		{
			Content.Render(ctx);
			return;
		}

		// Otherwise render text
		if (mContentText == null || mContentText.Length == 0)
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
				ctx.DrawText(mContentText, font, atlas, atlasTexture, bounds, .Left, .Middle, foreground);
				return;
			}
		}

		// Debug fallback - draw a rectangle to show where text would be
		#if DEBUG
		if (Context?.DebugSettings.ShowLayoutBounds ?? false)
		{
			let fontSize = FontSize;
			let textWidth = mContentText.Length * fontSize * FallbackCharWidthRatio;
			let textHeight = fontSize * FallbackLineHeightRatio;
			ctx.FillRect(.(bounds.X, bounds.Y, textWidth, textHeight), Color(foreground.R, foreground.G, foreground.B, 40));
		}
		#endif
	}

	/// Handles mouse down - focuses the target control if one is set.
	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		if (e.Button == .Left && IsEffectivelyEnabled)
		{
			// Focus the target control if set
			let target = mTarget.TryResolve();
			if (target != null && target.IsFocusable)
			{
				Context?.FocusManager?.SetFocus(target);
				e.Handled = true;
			}
		}
		base.OnMouseDown(e);
	}
}
