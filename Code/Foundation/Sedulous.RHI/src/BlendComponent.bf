namespace Sedulous.RHI;

/// One side of a blend equation, being source times its factor, combined with destination
/// times its factor.
struct BlendComponent
{
	public BlendFactor SrcFactor = .One;
	public BlendFactor DstFactor = .Zero;
	public BlendOperation Operation = .Add;

	public this() {}

	public this(BlendFactor srcFactor, BlendFactor dstFactor, BlendOperation operation)
	{
		SrcFactor = srcFactor; DstFactor = dstFactor; Operation = operation;
	}
}
