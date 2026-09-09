using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.Render;

/// What a built cluster grid exposes to the forward pass: the buffers, and the parameters the
/// shader maps a pixel and a depth through to reach its cluster.
struct ClusterBinding
{
	/// Per cluster: where its light list starts, and how long it is.
	public IBuffer Offsets = null;
	/// The flat list those index into.
	public IBuffer LightIndices = null;

	/// Bumped whenever this slot's buffers are REALLOCATED.
	///
	/// A consumer caching a bind group has to invalidate on a change of this rather than
	/// comparing the buffers: a freed buffer's address is reused by the new allocation, so
	/// equality there is a use after free that looks like nothing happened.
	public uint32 Version = 0;

	/// The graph handles, so the forward pass can declare the reads and be ordered after the
	/// build that wrote them.
	public RGHandle OffsetsHandle = .Invalid;
	public RGHandle IndicesHandle = .Invalid;

	public uint32 GridX = 0;
	public uint32 GridY = 0;
	public uint32 SliceCount = 0;
	public uint32 TileSize = 0;

	/// The grid is VIEWPORT LOCAL, so the forward pass subtracts this from the pixel
	/// position: a split screen view's clusters are its own rather than the window's.
	public int32 ViewportX = 0;
	public int32 ViewportY = 0;

	public float NearZ = 0.0f;
	public float FarZ = 0.0f;
	/// The logarithmic depth slicing, precomputed so the shader multiplies and adds rather
	/// than dividing.
	public float LogScale = 0.0f;
	public float LogBias = 0.0f;

	public this() {}

	public bool Valid => (Offsets != null) && (LightIndices != null);
}
