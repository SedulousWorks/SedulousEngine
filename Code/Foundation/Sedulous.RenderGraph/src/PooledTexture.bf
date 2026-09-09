using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// One texture waiting in the transient pool.
struct PooledTexture
{
	public TextureDesc Desc = .();
	public ITexture Texture = null;
	public ITextureView View = null;
	/// The stable identity of THIS physical texture, carried across pool reuse.
	public uint64 Generation = 0;
	public int32 UnusedFrames = 0;

	public this() {}

	public this(TextureDesc desc, ITexture texture, ITextureView view, uint64 generation)
	{
		Desc = desc;
		Texture = texture;
		View = view;
		Generation = generation;
	}
}
