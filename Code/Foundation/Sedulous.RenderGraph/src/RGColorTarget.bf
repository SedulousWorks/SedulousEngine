using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// A colour attachment of a render pass.
struct RGColorTarget
{
	public RGHandle Handle = .Invalid;
	public LoadOp LoadOp = .Clear;
	public StoreOp StoreOp = .Store;
	public ClearColor ClearValue = .Black;
	public RGSubresourceRange Subresource = .();

	/// Where the multisampled attachment RESOLVES to at the end of the pass.
	///
	/// Valid means the hardware resolve runs, which averages the samples and is the correct
	/// resolve for scene colour. The multisampled attachment's store then becomes a discard,
	/// since its samples are not wanted afterwards. Invalid is the single sampled path.
	public RGHandle ResolveHandle = .Invalid;

	public this() {}
}
