namespace Sedulous.RHI;

/// The depth stencil attachment of a render pass.
///
/// Depth and stencil carry their own load and store ops because a pass commonly clears one
/// and preserves the other.
struct DepthStencilAttachment
{
	public ITextureView View = null;

	public LoadOp DepthLoadOp = .Clear;
	public StoreOp DepthStoreOp = .Store;
	/// One, being the far plane under the usual Less test.
	public float DepthClearValue = 1.0f;
	/// Declares the pass will not WRITE depth, which lets the same texture be sampled while
	/// it is attached.
	public bool DepthReadOnly = false;

	public LoadOp StencilLoadOp = .Clear;
	public StoreOp StencilStoreOp = .Store;
	public uint32 StencilClearValue = 0;
	public bool StencilReadOnly = false;

	public this() {}
}
