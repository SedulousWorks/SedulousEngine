using Sedulous.RHI;

namespace Sedulous.RHI.Null;

class NullTextureView : ITextureView
{
	private TextureViewDesc mDesc;
	private ITexture mTexture;

	/// Stamped at construction from the shared sequence, so even the null backend's views
	/// carry ids that never repeat. That is what lets a cache keyed on a view be tested
	/// headlessly.
	private readonly uint64 mUniqueId = TextureViewIds.Next();

	public TextureViewDesc Desc => mDesc;
	public ITexture Texture => mTexture;
	public uint64 UniqueId => mUniqueId;

	public void Initialize(ITexture texture, TextureViewDesc desc)
	{
		mTexture = texture;
		mDesc = desc;
	}
}
