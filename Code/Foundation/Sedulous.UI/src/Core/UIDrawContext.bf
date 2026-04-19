namespace Sedulous.UI;

using Sedulous.VG;
using Sedulous.Fonts;
using Sedulous.Core.Mathematics;
using System;

/// Wrapper over VGContext that widgets draw to. Provides VG access,
/// font service, theme, and debug overlay state.
public class UIDrawContext
{
	private VGContext mVG;
	private float mUIScale;
	private IFontService mFontService;
	private Theme mTheme;
	private UIDebugDrawSettings mDebugSettings;

	/// Direct access to the underlying VGContext for custom drawing.
	public VGContext VG => mVG;

	/// Current UI scale.
	public float UIScale => mUIScale;

	/// Font service for text rendering.
	public IFontService FontService => mFontService;

	/// Active theme.
	public Theme Theme => mTheme;

	/// Debug draw settings.
	public UIDebugDrawSettings DebugSettings => mDebugSettings;

	public this(VGContext vg, float uiScale = 1.0f, IFontService fontService = null,
		Theme theme = null, UIDebugDrawSettings debugSettings = .())
	{
		mVG = vg;
		mUIScale = uiScale;
		mFontService = fontService;
		mTheme = theme;
		mDebugSettings = debugSettings;
	}

	/// Push a scissor clip rect (logical coordinates).
	public void PushClip(RectangleF rect) => mVG.PushClipRect(rect);

	/// Pop the current clip.
	public void PopClip() => mVG.PopClip();

	// === Theme-key helpers ===

	/// Try to draw a theme drawable. Returns true if a drawable was found and drawn.
	/// Controls use this for Option C pattern: drawable first, color fallback.
	public bool TryDrawDrawable(StringView key, RectangleF bounds, ControlState state = .Normal)
	{
		if (mTheme == null) return false;
		let d = mTheme.GetDrawable(key);
		if (d != null)
		{
			d.Draw(this, bounds, state);
			return true;
		}
		return false;
	}

	/// Fill a rect with the color from a theme key.
	public void FillBackground(RectangleF bounds, StringView themeKey)
	{
		if (mTheme == null) return;
		let color = mTheme.GetColor(themeKey, .Transparent);
		if (color.A > 0)
			mVG.FillRect(bounds, color);
	}

	/// Stroke a rect border with color and width from theme keys.
	public void DrawBorder(RectangleF bounds, StringView colorKey, StringView widthKey = "")
	{
		if (mTheme == null) return;
		let color = mTheme.GetColor(colorKey, .Transparent);
		let width = (widthKey.Length > 0) ? mTheme.GetDimension(widthKey, 1) : 1.0f;
		if (color.A > 0 && width > 0)
			mVG.StrokeRect(bounds, color, width);
	}

	/// Draw text using a theme color key and font size key.
	public void DrawText(StringView text, RectangleF bounds, StringView colorKey,
		Sedulous.Fonts.TextAlignment hAlign = .Left, Sedulous.Fonts.VerticalAlignment vAlign = .Middle,
		float fontSize = 16)
	{
		if (mTheme == null || mFontService == null) return;
		let color = mTheme.GetColor(colorKey, .(220, 225, 235, 255));
		let font = mFontService.GetFont(fontSize);
		if (font != null)
			mVG.DrawText(text, font, bounds, hAlign, vAlign, color);
	}

	/// Draw a theme Drawable at the given bounds.
	public void DrawDrawable(StringView drawableKey, RectangleF bounds,
		ControlState state = .Normal)
	{
		if (mTheme == null) return;
		let drawable = mTheme.GetDrawable(drawableKey);
		if (drawable != null)
			drawable.Draw(this, bounds, state);
	}

	/// Draw a themed box (fill + border + corner radius) using keys:
	/// "{prefix}.Background", "{prefix}.Border", "{prefix}.CornerRadius", "{prefix}.BorderWidth".
	/// Reduces boilerplate in Panel, Button, Dialog, etc.
	public void FillThemedBox(RectangleF bounds, StringView prefix,
		Color defaultBg = .Transparent, Color defaultBorder = .Transparent,
		float defaultRadius = 0, float defaultBorderWidth = 0)
	{
		if (mTheme == null) return;

		let bgKey = scope $"{prefix}.Background";
		let borderKey = scope $"{prefix}.Border";
		let radiusKey = scope $"{prefix}.CornerRadius";
		let widthKey = scope $"{prefix}.BorderWidth";

		let bgColor = mTheme.GetColor(bgKey, defaultBg);
		let borderColor = mTheme.GetColor(borderKey, defaultBorder);
		let radius = mTheme.GetDimension(radiusKey, defaultRadius);
		let borderWidth = mTheme.GetDimension(widthKey, defaultBorderWidth);

		if (bgColor.A > 0)
		{
			if (radius > 0)
				mVG.FillRoundedRect(bounds, radius, bgColor);
			else
				mVG.FillRect(bounds, bgColor);
		}

		if (borderColor.A > 0 && borderWidth > 0)
		{
			if (radius > 0)
				mVG.StrokeRoundedRect(bounds, radius, borderColor, borderWidth);
			else
				mVG.StrokeRect(bounds, borderColor, borderWidth);
		}
	}

	/// Draw a standard focus ring around bounds using theme colors.
	/// cornerRadius should match the control's corner radius.
	public void DrawFocusRing(RectangleF bounds, float cornerRadius = 0, float ringWidth = 2.0f)
	{
		let ringColor = mTheme?.GetColor("Focus.Ring", .(100, 160, 255, 180)) ?? .(100, 160, 255, 180);
		let outset = RectangleF(bounds.X - 1, bounds.Y - 1, bounds.Width + 2, bounds.Height + 2);
		if (cornerRadius > 0)
			mVG.StrokeRoundedRect(outset, cornerRadius + 1, ringColor, ringWidth);
		else
			mVG.StrokeRect(outset, ringColor, ringWidth);
	}
}
