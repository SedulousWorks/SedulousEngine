using Sedulous.RHI;

namespace Sedulous.Render;

/// The display referred grading table, applied after the tone map operator.
///
/// A static cooked texture, whose IDENTITY keys the bind group cache rather than its pointer.
/// A table of fewer than two slices, or a null view, disables it.
struct TonemapGrading
{
	public ITextureView View = null;
	public uint64 Uid = 0;
	public float LutSize = 0.0f;
	public float Intensity = 1.0f;

	public this() {}
}
