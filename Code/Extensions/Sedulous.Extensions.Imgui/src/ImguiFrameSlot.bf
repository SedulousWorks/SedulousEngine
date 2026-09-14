using Sedulous.RHI;

namespace Sedulous.Extensions.Imgui;

/// One frame in flight's own geometry, projection and bindings.
///
/// PER FRAME because the GPU may still be reading last frame's vertices while this one is
/// being written: one shared buffer would have the interface tearing under its own overlay.
class ImguiFrameSlot
{
	public IBuffer Vertices = null;
	public uint64 VertexCapacity = 0;
	public IBuffer Indices = null;
	public uint64 IndexCapacity = 0;
	public IBuffer Projection = null;
	public IBindGroup Bindings = null;
}
