namespace Sedulous.VG.Renderer;

/// Where one batch's data landed in the shared frame buffers.
///
/// Handed out by Prepare and consumed by Render. An INVALID slice draws nothing, which is
/// what a batch that did not fit or had nothing in it produces.
struct VGRenderSlice
{
	public uint32 VertexByteOffset = 0;
	public uint32 IndexByteOffset = 0;
	/// The slice's analytic boxes, after its ordinary vertices in the same buffer.
	public uint32 BoxVertexByteOffset = 0;
	public uint32 UniformByteOffset = 0;
	public int32 DrawCommandStart = 0;
	public int32 DrawCommandCount = 0;
	/// The slice's offscreen layers (VGBatch.Layers), drawn by RenderLayers.
	public int32 LayerStart = 0;
	public int32 LayerCount = 0;
	public bool IsValid = false;

	public this() {}
}
