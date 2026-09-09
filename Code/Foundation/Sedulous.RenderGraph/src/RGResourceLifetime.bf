namespace Sedulous.RenderGraph;

/// How long a graph resource lives.
enum RGResourceLifetime : uint8
{
	/// Created and destroyed by the graph, and its memory reused by anything whose lifetime
	/// does not overlap.
	case Transient;
	/// Survives the frame, so its contents carry over: history buffers and accumulations.
	case Persistent;
	/// Owned by the caller, which the graph only reads and writes: the swap chain's image.
	case Imported;
}
