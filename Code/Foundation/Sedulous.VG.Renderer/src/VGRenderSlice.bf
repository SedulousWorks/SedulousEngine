namespace Sedulous.VG.Renderer;

/// Where one batch's data landed in the shared frame buffers.
///
/// Handed out by Prepare and consumed by Render. An INVALID slice draws nothing, which is
/// what a batch that did not fit or had nothing in it produces.
struct VGRenderSlice
{
	public uint32 VertexByteOffset = 0;
	public uint32 IndexByteOffset = 0;
	public uint32 UniformByteOffset = 0;
	public int32 DrawCommandStart = 0;
	public int32 DrawCommandCount = 0;
	public bool IsValid = false;

	public this() {}
}
