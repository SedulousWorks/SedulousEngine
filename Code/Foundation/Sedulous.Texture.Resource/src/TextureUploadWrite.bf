using Sedulous.RHI;

namespace Sedulous.Texture.Resource;

/// One WriteTexture an upload will make: which slice of the cooked payload goes where.
struct TextureUploadWrite
{
	/// Into the cooked payload.
	public int Offset = 0;
	public int ByteCount = 0;

	public TextureDataLayout Layout = .();
	public Extent3D Extent = .();
	public uint32 MipLevel = 0;
	public uint32 ArrayLayer = 0;

	public this() {}
}
