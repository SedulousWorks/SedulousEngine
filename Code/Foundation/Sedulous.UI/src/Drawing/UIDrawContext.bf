using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.VG;

namespace Sedulous.UI;

/// The drawing context handed to View.OnDraw: a vector graphics context with clip stacking,
/// plus the font service and the DPI scale.
class UIDrawContext
{
	private VGContext mVG;
	private DrawBlend mBlend = .();
	private float mDpiScale;
	private IFontService mFontService;
	private UIDebugDrawSettings mDebugSettings;

	/// BORROWS everything: the context, the font service and the settings all outlive this.
	public this(VGContext context, float dpiScale, IFontService fontService = null,
		UIDebugDrawSettings debugSettings = .())
	{
		mVG = context;
		mDpiScale = dpiScale;
		mFontService = fontService;
		mDebugSettings = debugSettings;
	}

	public VGContext VG => mVG;
	public float DpiScale => mDpiScale;
	/// May be null.
	public IFontService FontService => mFontService;
	public UIDebugDrawSettings DebugSettings => mDebugSettings;

	/// The view being drawn, whose custom properties a drawable's `var(--name)` colours resolve
	/// against: DrawChildren sets it around each view's drawing and puts the previous one back.
	/// BORROWED; null outside a view's drawing.
	public View ColorSource = null;

	/// A drawable's colour: the custom property `variable` names, if the view being drawn has it
	/// as a colour, else `value` (the var()'s fallback, or the colour written).
	public Color ColorOf(Color value, StringView variable)
	{
		if (variable.IsEmpty || (ColorSource == null))
			return value;
		let found = ColorSource.CustomProperty(variable).AsColor;
		return found.HasValue ? found.Value : value;
	}

	/// Pushes a clip rectangle, in the current local coordinates.
	public void PushClip(Rectangle rect) => mVG.PushClipRect(rect);
	public void PopClip() => mVG.PopClip();
	/// Clips to `rect` rounded by `radii` (current local coordinates), inside any rounded clip
	/// already pushed. Balance with PopClipRounded.
	public void PushClipRounded(Rectangle rect, CornerRadii radii)
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildRoundedRect(rect, radii, builder);
		let path = builder.ToPath();
		defer delete path;
		mVG.PushClipPath(path);
	}
	/// Pops the last rounded clip.
	public void PopClipRounded() => mVG.PopClipPath();

	/// Whether a rectangle can contribute any pixels under the active clip, and true when
	/// there is no clip.
	///
	/// The child draw loop culls with this, so a subtree clipped entirely away costs no
	/// tessellation at all: draw lists stay viewport sized rather than content sized.
	public bool IsRectVisible(Rectangle rect) => mVG.IsRectVisible(rect);

	/// Sets what the next Drawable.Draw will blend, answering the PREVIOUS value so a caller
	/// can put it back.
	public DrawBlend SetBlend(DrawBlend blend)
	{
		let previous = mBlend;
		mBlend = blend;
		return previous;
	}

	public DrawBlend Blend => mBlend;
}
