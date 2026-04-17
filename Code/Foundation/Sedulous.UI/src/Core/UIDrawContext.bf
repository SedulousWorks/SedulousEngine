namespace Sedulous.UI;

using Sedulous.VG;
using Sedulous.Fonts;
using Sedulous.Core.Mathematics;

/// Wrapper over VGContext that widgets draw to. Provides VG access,
/// font service access, and debug overlay state.
public class UIDrawContext
{
	private VGContext mVG;
	private float mUIScale;
	private IFontService mFontService;
	private UIDebugDrawSettings mDebugSettings;

	/// Direct access to the underlying VGContext for custom drawing.
	public VGContext VG => mVG;

	/// Current UI scale (for DPI-aware decisions inside custom draw code).
	public float UIScale => mUIScale;

	/// Font service for text rendering. May be null if no fonts loaded.
	public IFontService FontService => mFontService;

	/// Debug draw settings (which overlays are enabled).
	public UIDebugDrawSettings DebugSettings => mDebugSettings;

	public this(VGContext vg, float uiScale = 1.0f, IFontService fontService = null,
		UIDebugDrawSettings debugSettings = .())
	{
		mVG = vg;
		mUIScale = uiScale;
		mFontService = fontService;
		mDebugSettings = debugSettings;
	}

	/// Push a scissor clip rect (logical coordinates).
	public void PushClip(RectangleF rect) => mVG.PushClipRect(rect);

	/// Pop the current clip.
	public void PopClip() => mVG.PopClip();
}
