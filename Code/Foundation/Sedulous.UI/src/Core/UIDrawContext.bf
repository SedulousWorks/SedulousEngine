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
}
