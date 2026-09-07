namespace Sedulous.RHI;

/// One texture to texture copy.
struct TextureCopyRegion
{
	public uint32 SrcMipLevel = 0;
	public uint32 SrcArrayLayer = 0;
	public uint32 DstMipLevel = 0;
	public uint32 DstArrayLayer = 0;
	public Extent3D Extent = .();

	public this() {}
}
