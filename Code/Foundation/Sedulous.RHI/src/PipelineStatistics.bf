namespace Sedulous.RHI;

/// The counters of one pipeline statistics query, whatever layout a backend resolves them in
/// (IDevice.DecodePipelineStatistics).
struct PipelineStatistics
{
	/// Vertices the input assembler read, and the primitives it assembled.
	public uint64 InputVertices;
	public uint64 InputPrimitives;
	/// Vertex shader runs.
	public uint64 VertexInvocations;
	/// Primitives that came out of clipping, toward the rasterizer.
	public uint64 ClippingPrimitives;
	/// Fragment (pixel) shader runs.
	public uint64 FragmentInvocations;
	/// Compute shader runs.
	public uint64 ComputeInvocations;
}
