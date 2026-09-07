using Sedulous.RHI;

namespace Sedulous.RHI.Null;

class NullTexture : ITexture
{
	private TextureDesc mDesc;

	public TextureDesc Desc => mDesc;
	public ResourceState InitialState { get; set; } = .Undefined;

	public void Initialize(TextureDesc desc) => mDesc = desc;
}
