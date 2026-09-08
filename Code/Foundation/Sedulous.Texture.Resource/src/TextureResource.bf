using Sedulous.Core.Serialization;
using Sedulous.RHI;
using Sedulous.Texture;

namespace Sedulous.Texture.Resource;

/// The cooked texture RECORD: everything about a texture except its pixels.
///
/// The pixels live in the instance's "data" stream rather than in here, because they are
/// the heavy part and a database browsing a thousand textures wants a thousand headers,
/// not a thousand images.
///
/// Nothing binds this directly. It is what the factory reads to build the live product.
[Serializable]
class TextureResource
{
	public uint32 Width = 0;
	public uint32 Height = 0;
	/// The depth of a volume, or the layer count of an array. A cubemap ignores it and
	/// uses six.
	public uint32 DepthOrArrayLayers = 1;
	public uint32 MipLevels = 1;

	public TextureFormat Format = .RGBA8Unorm;
	public TextureShape Shape = .Texture2D;

	public TextureFilter MinFilter = .Linear;
	public TextureFilter MagFilter = .Linear;
	public TextureWrap WrapU = .Repeat;
	public TextureWrap WrapV = .Repeat;
	public TextureWrap WrapW = .Repeat;

	/// Whether the COOK should build a chain. The runtime reads MipLevels, which says what
	/// the payload actually holds.
	public bool GenerateMipmaps = true;

	public float Anisotropy = 1.0f;
}
