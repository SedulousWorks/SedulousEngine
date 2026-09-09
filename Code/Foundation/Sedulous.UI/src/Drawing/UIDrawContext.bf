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

	/// Pushes a clip rectangle, in the current local coordinates.
	public void PushClip(Rectangle rect) => mVG.PushClipRect(rect);
	public void PopClip() => mVG.PopClip();

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
