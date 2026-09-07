namespace Sedulous.RHI;

/// A size in texels.
///
/// Height and depth default to ONE, not zero, so a 1D or 2D extent is valid with only the
/// dimensions it uses set: a zero would make the region empty rather than flat.
struct Extent3D
{
	public uint32 Width = 0;
	public uint32 Height = 1;
	public uint32 Depth = 1;

	public this() {}

	public this(uint32 width, uint32 height = 1, uint32 depth = 1)
	{
		Width = width; Height = height; Depth = depth;
	}
}
