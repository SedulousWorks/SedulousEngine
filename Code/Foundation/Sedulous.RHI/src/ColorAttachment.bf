namespace Sedulous.RHI;

/// One colour attachment of a render pass.
struct ColorAttachment
{
	public ITextureView View = null;
	/// Where a multisampled attachment resolves to. Null means no resolve.
	public ITextureView ResolveTarget = null;
	public LoadOp LoadOp = .Clear;
	public StoreOp StoreOp = .Store;
	public ClearColor ClearValue = ClearColor.Black;

	public this() {}
}
