using System;

namespace Sedulous.VG.Renderer;

/// One layer blur pass's uniforms (vg_blur.ps's VGBlur), in a VGUniforms sized slot.
[CRepr]
struct VGBlurUniforms
{
	/// One texel along the pass's axis, in texture coordinates.
	public float[2] Step = .(0.0f, 0.0f);
	/// The content's extent in texture coordinates; the target may be larger.
	public float[2] Region = .(1.0f, 1.0f);
	public float Sigma = 1.0f;
	/// Taps each side.
	public float Radius = 0.0f;
	public float[2] Unused = .(0.0f, 0.0f);

	public this() {}
}
