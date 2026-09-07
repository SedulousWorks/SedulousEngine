namespace Sedulous.RHI;

/// The stencil test and its three outcomes, for one facing.
struct StencilFaceState
{
	public CompareFunction Compare = .Always;
	/// Applied when the STENCIL test fails.
	public StencilOperation FailOp = .Keep;
	/// Applied when the stencil test passes but the DEPTH test fails.
	public StencilOperation DepthFailOp = .Keep;
	/// Applied when both pass.
	public StencilOperation PassOp = .Keep;

	public this() {}
}
