using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Internal state for VGContext
struct VGState
{
	public Matrix Transform = Matrix.Identity;
	public RectangleF ClipRect = default;
	public VGClipMode ClipMode = .None;
	public float Opacity = 1.0f;
	public int32 StencilRef = 0;
}
