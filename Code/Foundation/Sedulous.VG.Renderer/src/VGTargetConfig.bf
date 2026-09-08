using Sedulous.RHI;

namespace Sedulous.VG.Renderer;

/// What the HOST's render target looks like.
///
/// Both values apply to EVERY pipeline, not only the stencil ones: a pipeline must match
/// the pass it is used in, so one pipeline declaring the attachment and another not is a
/// mismatch rather than an optimisation.
struct VGTargetConfig
{
	/// Above one means the host renders into a multisampled target and resolves it itself.
	public uint32 SampleCount = 1;

	/// Anything but Undefined means the pass carries that attachment, with the stencil
	/// cleared to zero by the host. That is what unlocks the stencil then cover fills.
	public TextureFormat DepthStencilFormat = .Undefined;

	public this() {}
}
