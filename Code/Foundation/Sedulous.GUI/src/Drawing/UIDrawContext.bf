namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.VG;
using Sedulous.Fonts;

/// Drawing context passed to View.OnDraw(). Wraps a VGContext with
/// transform/clip stacking and provides access to fonts and DPI scale.
public class UIDrawContext
{
	private VGContext mVG;
	private float mDpiScale;
	private IFontService mFontService;
	private UIDebugDrawSettings mDebugSettings;

	/// The underlying vector graphics context.
	public VGContext VG => mVG;

	/// Current DPI scale.
	public float DpiScale => mDpiScale;

	/// Font service for text rendering.
	public IFontService FontService => mFontService;

	/// Debug overlay settings.
	public UIDebugDrawSettings DebugSettings => mDebugSettings;

	public this(VGContext vg, float dpiScale, IFontService fontService = null, UIDebugDrawSettings debugSettings = .())
	{
		mVG = vg;
		mDpiScale = dpiScale;
		mFontService = fontService;
		mDebugSettings = debugSettings;
	}

	/// Pushes a clip rectangle (in current local coordinates).
	public void PushClip(RectangleF rect)
	{
		mVG.PushClipRect(rect);
	}

	/// Pops the last pushed clip.
	public void PopClip()
	{
		mVG.PopClip();
	}
}
