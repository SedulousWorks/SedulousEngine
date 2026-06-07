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

	public VGContext VG => mVG;
	public float DpiScale => mDpiScale;
	public IFontService FontService => mFontService;
	public UIDebugDrawSettings DebugSettings => mDebugSettings;

	public this(VGContext vg, float dpiScale, IFontService fontService = null, UIDebugDrawSettings debugSettings = .())
	{
		mVG = vg;
		mDpiScale = dpiScale;
		mFontService = fontService;
		mDebugSettings = debugSettings;
	}

	public void PushClip(RectangleF rect)
	{
		mVG.PushClipRect(rect);
	}

	public void PopClip()
	{
		mVG.PopClip();
	}
}
