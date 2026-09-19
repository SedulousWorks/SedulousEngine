using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// The depth and stencil attachment of a render pass.
struct RGDepthTarget
{
	public RGHandle Handle = .Invalid;
	public LoadOp DepthLoadOp = .Clear;
	public StoreOp DepthStoreOp = .Store;
	public float DepthClearValue = Depth.ClearValue; // the far plane
	/// Declares the pass will not WRITE depth, which lets the same texture be sampled while
	/// it is attached.
	public bool ReadOnly = false;

	public LoadOp StencilLoadOp = .DontCare;
	public StoreOp StencilStoreOp = .DontCare;
	public uint32 StencilClearValue = 0;

	public RGSubresourceRange Subresource = .();

	public this() {}
}
