using System;

namespace Sedulous.RHI;

struct SamplerDesc
{
	public FilterMode MinFilter = .Linear;
	public FilterMode MagFilter = .Linear;
	public MipmapFilterMode MipmapFilter = .Linear;
	public AddressMode AddressU = .Repeat;
	public AddressMode AddressV = .Repeat;
	public AddressMode AddressW = .Repeat;
	public float MipLodBias = 0.0f;
	public float MinLod = 0.0f;
	/// A thousand rather than a real maximum: it is past any mip chain, so it means "no
	/// clamp" without needing to know the texture.
	public float MaxLod = 1000.0f;
	public uint16 MaxAnisotropy = 1;

	/// Set to make this a COMPARISON sampler, which is what shadow map filtering uses.
	/// Null leaves it an ordinary one.
	public CompareFunction? Compare = null;

	public SamplerBorderColor BorderColor = .TransparentBlack;
	public StringView Label = default;

	public this() {}
}
