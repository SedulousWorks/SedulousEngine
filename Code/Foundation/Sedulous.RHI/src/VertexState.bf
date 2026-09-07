using System;

namespace Sedulous.RHI;

struct VertexState
{
	public ProgrammableStage Shader = .();
	/// One layout per bound vertex buffer slot, in slot order.
	public Span<VertexBufferLayout> Buffers = default;

	public this() {}
}
