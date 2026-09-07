namespace Sedulous.RHI;

/// Whether a render pass writes an attachment back when it ends. DontCare lets a tiler skip
/// the resolve entirely, which is what makes a transient depth buffer cheap.
enum StoreOp : uint32
{
	Store,
	DontCare
}
