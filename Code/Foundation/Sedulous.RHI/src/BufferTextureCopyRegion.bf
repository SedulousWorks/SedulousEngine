namespace Sedulous.RHI;

/// One copy between a buffer and a texture, in either direction.
struct BufferTextureCopyRegion
{
	public uint64 BufferOffset = 0;
	/// The row stride in the BUFFER, subject to the backend's alignment. See
	/// TextureDataLayout for why this is not simply the row width.
	public uint32 BytesPerRow = 0;
	public uint32 RowsPerImage = 0;

	public uint32 TextureMipLevel = 0;
	public uint32 TextureArrayLayer = 0;
	public Origin3D TextureOrigin = .();
	public Extent3D TextureExtent = .();

	public this() {}
}
