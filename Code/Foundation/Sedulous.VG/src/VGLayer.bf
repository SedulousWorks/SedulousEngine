using Sedulous.Core;

namespace Sedulous.VG;

/// One offscreen layer (VGContext.PushLayer): drawn into a target of its own and composited into
/// its parent once, so a group fades as one.
struct VGLayer
{
	/// The enclosing layer, -1 for the target itself.
	public int32 Parent = -1;
	/// Its content's device bounds, on whole pixels; empty when nothing was drawn.
	public Rectangle Bounds = .();
	/// Applied once, at the composite.
	public float Opacity = 1.0f;
	/// How the composite blends into the parent.
	public VGBlendMode BlendMode = .Normal;
	/// A Gaussian blur's sigma in device pixels, 0 for none; the bounds carry three sigmas.
	public float Blur = 0.0f;
	/// The sigma of a blurred copy drawn for backdrop composites; the layer itself stays sharp.
	public float BackdropBlur = 0.0f;
	/// Colour filters applied at the composite: 0 is grey and 1 unchanged (CSS's saturate(),
	/// grayscale() its complement), and a factor on the colour (brightness()).
	public float Saturation = 1.0f;
	public float Brightness = 1.0f;

	public this() {}
}
