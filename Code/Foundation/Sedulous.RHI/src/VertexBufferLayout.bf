using System;

namespace Sedulous.RHI;

/// How one bound vertex buffer is read.
struct VertexBufferLayout
{
	/// Bytes between consecutive elements.
	public uint32 Stride = 0;
	/// Whether an element is per vertex or per instance.
	public VertexStepMode StepMode = .Vertex;
	public Span<VertexAttribute> Attributes = default;

	public this() {}
}
