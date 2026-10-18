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
	/// Stencil clipped AND confined to ClipRect (a rectangle clip inside a path clip); an empty
	/// ClipRect hides the draw. Scissor mode commands are always confined to ClipRect.
	public bool Scissored = false;
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
	/// The layer whose offscreen target this command draws into (VGBatch.Layers), -1 for the
	/// target itself.
	public int32 Layer = -1;
	/// A Layer mode composite: the layer whose target the quad samples.
	public int32 CompositeLayer = -1;

	public this() {}
}
