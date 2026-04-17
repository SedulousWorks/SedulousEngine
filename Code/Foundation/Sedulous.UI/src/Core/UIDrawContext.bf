namespace Sedulous.UI;

using Sedulous.VG;
using Sedulous.Fonts;
using Sedulous.Core.Mathematics;

/// Thin wrapper over VGContext that widgets draw to. Phase 1: bare VG pass-through.
/// Phase 2 adds drawable helpers; Phase 4 adds theme-key-based overloads.
public class UIDrawContext
{
	private VGContext mVG;
	private float mUIScale;

	/// Direct access to the underlying VGContext for custom drawing.
	public VGContext VG => mVG;

	/// Current UI scale (for DPI-aware decisions inside custom draw code).
	public float UIScale => mUIScale;

	public this(VGContext vg, float uiScale = 1.0f)
	{
		mVG = vg;
		mUIScale = uiScale;
	}

	/// Push a scissor clip rect (logical coordinates).
	public void PushClip(RectangleF rect) => mVG.PushClipRect(rect);

	/// Pop the current clip.
	public void PopClip() => mVG.PopClip();
}
