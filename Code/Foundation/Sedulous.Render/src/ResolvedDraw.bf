using Sedulous.RHI;

namespace Sedulous.Render;

/// A FULLY RESOLVED draw: every piece of GPU state settled, ready to emit as pure commands.
///
/// This is the split that makes parallel command recording possible. Resolving allocates,
/// uploads and caches, and happens on one thread; emitting touches NO shared state, so it can
/// run across threads or into off thread bundles.
///
/// The bind groups follow the engine's set frequency convention, which every renderer keeps
/// to: the view per frame, the object per draw, then the material, then the light lists.
struct ResolvedDraw
{
	public IRenderPipeline Pso = null;

	public IBindGroup ViewSet = null;
	public uint32 ViewOffset = 0;
	public bool ViewDynamic = false;

	public IBindGroup DrawSet = null;
	public uint32 DrawOffset = 0;
	public bool DrawDynamic = false;

	public IBindGroup MaterialSet = null;
	public IBindGroup ClusterSet = null;

	public IBuffer VertexBuffer0 = null;
	public uint64 VertexOffset0 = 0;
	/// The skinning stream, or the instance offsets.
	public IBuffer VertexBuffer1 = null;
	public uint64 VertexOffset1 = 0;
	/// The instance offsets, where the skinning stream took the slot above.
	public IBuffer VertexBuffer2 = null;
	public uint64 VertexOffset2 = 0;

	public IBuffer IndexBuffer = null;
	public uint64 IndexOffset = 0;
	public IndexFormat IndexFormat = .UInt32;
	public uint32 IndexCount = 0;
	public uint32 InstanceCount = 1;

	public this() {}
}
