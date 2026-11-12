using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.Render;

/// Everything a SCREEN overlay source needs to draw into one window target.
///
/// Screen tier content is window space chrome: screen UI, profiler displays, editor overlays.
/// The host makes one call per window target after the scene composed.
struct ScreenOverlayView
{
	public uint32 Width = 0;
	public uint32 Height = 0;
	public TextureFormat TargetFormat = .BGRA8Unorm;
	/// The same contract as the scene tier's: set only when the pass carries one.
	public TextureFormat DepthStencilFormat = .Undefined;
	public uint32 FrameIndex = 0;
	/// The pass draws through a UNORM view of an sRGB target (TargetFormat is that view's):
	/// overlays keep colours encoded and blend them so, as browsers composite UI (VG's Encoded
	/// blend space). False: the target as it is, linear light.
	public bool EncodedTarget = false;
	/// The part of the window nothing of the system covers (a phone's bars, its camera's cutout),
	/// in the window's pixels, which a game's screens keep inside; empty (no width): the whole
	/// window.
	public Rectangle SafeArea = .();
	/// How the target's content is turned from the window's picture, clockwise: None unless the
	/// window draws pre-rotated for a display that presents turned (a phone held away from its
	/// natural orientation). Overlays lay out and draw in the window's space (WindowSize) and take
	/// WindowToTarget onto what they draw, so each lands turned where the display shows it upright;
	/// on a quarter turn the target is the window with its sides swapped.
	public ContentRotation PreRotation = .None;

	public this() {}

	/// The window's size: the target's, its sides swapped on a quarter turn.
	public Float2 WindowSize
	{
		get
		{
			let target = Float2((float)Width, (float)Height);
			return ContentFit.TurnSwapsSides(PreRotation) ? Float2(target.Y, target.X) : target;
		}
	}

	/// Where a rectangle of the window lands on the target (ContentFit.TurnRectangle).
	public Rectangle WindowToTarget(Rectangle rect) => ContentFit.TurnRectangle(rect, PreRotation, WindowSize);

	/// The affine that takes a window point to the target's (row vectors: a point times it), the
	/// identity when nothing is turned: what an overlay drawing in window space puts after its own
	/// transform.
	public Float4x4 WindowToTargetTransform
	{
		get
		{
			let size = WindowSize;
			let origin = ContentFit.TurnPoint(.(0, 0), PreRotation, size);
			let xAxis = ContentFit.TurnPoint(.(1, 0), PreRotation, size);
			let yAxis = ContentFit.TurnPoint(.(0, 1), PreRotation, size);
			return Float4x4(
				xAxis.X - origin.X, xAxis.Y - origin.Y, 0, 0,
				yAxis.X - origin.X, yAxis.Y - origin.Y, 0, 0,
				0, 0, 1, 0,
				origin.X, origin.Y, 0, 1);
		}
	}
}
