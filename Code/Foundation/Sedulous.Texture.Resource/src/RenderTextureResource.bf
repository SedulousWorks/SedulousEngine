using Sedulous.Core.Serialization;
using Sedulous.RHI;

namespace Sedulous.Texture.Resource;

/// The cooked render texture RECORD: a texture a camera renders into, with no pixels of its
/// own. Its product is an ordinary Texture, so whatever samples a texture (a sprite, a decal, a
/// material slot, a UI image) samples this one.
[Serializable]
class RenderTextureResource
{
	public const uint32 cMaxSize = 4096;

	public uint32 Width = 256;
	public uint32 Height = 256;
	public TextureFormat Format = .RGBA8UnormSrgb;

	/// A size the device can make and a format a camera can render to.
	public bool IsValid => (Width >= 1) && (Height >= 1) && (Width <= cMaxSize) && (Height <= cMaxSize)
		&& ((Format == .RGBA8UnormSrgb) || (Format == .RGBA16Float));
}
