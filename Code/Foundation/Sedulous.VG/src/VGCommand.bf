using Sedulous.Core;

namespace Sedulous.VG;

/// One draw call: a run of indices sharing render state.
///
/// A batch is split into these wherever the state changes, so the renderer walks a list of
/// state changes rather than re-deciding per triangle.
struct VGCommand
{
	public int32 StartIndex = 0;
	public int32 IndexCount = 0;
	/// Into the batch's texture list. Negative means none.
	public int32 TextureIndex = -1;

	/// In screen coordinates.
	public Rectangle ClipRect = .();
	public VGClipMode ClipMode = .None;
	public VGBlendMode BlendMode = .Normal;
	/// Which stencil value this draw tests or writes.
	public int32 StencilRef = 0;

	public VGDrawMode DrawMode = .Default;
	public VGFillPhase FillPhase = .Direct;
	/// Read only by the stencil write and cover phases, which is where the winding is
	/// actually resolved.
	public FillRule FillRule = .NonZero;
	/// The ramp sampler's address mode for this draw.
	public VGGradientSpread GradientSpread = .Pad;

	public this() {}
}
