using Sedulous.Core;

namespace Sedulous.VG;

/// One snapshot of a context's drawing state, as the state stack holds it.
struct VGState
{
	public Float4x4 Transform = .Identity();
	public Rectangle ClipRect = .();
	public VGClipMode ClipMode = .None;
	/// A rectangle clip is active (ClipRect, empty meaning nothing draws), alone (ClipMode
	/// Scissor) or inside path clips (ClipMode Stencil: the draw is scissored AND stencil tested).
	public bool Scissored = false;
	public float Opacity = 1.0f;
	public int32 StencilRef = 0;

	public this() {}
}
