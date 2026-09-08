using Sedulous.RHI;
using Sedulous.Texture;

namespace Sedulous.Texture.Resource;

/// The sampler a cooked record asks for.
///
/// Its own place rather than buried in the factory, because deriving a sampler needs no
/// device and is worth being able to check without one.
static class TextureSamplers
{
	public static SamplerDesc Describe(TextureResource record)
	{
		var desc = SamplerDesc();
		desc.MinFilter = ToFilterMode(record.MinFilter);
		desc.MagFilter = ToFilterMode(record.MagFilter);

		// Trilinear whenever a chain actually EXISTS. A model import says Linear and means
		// it about the texels, not about the mips, and nearest mip banding on a real chain
		// is never what anybody wanted.
		desc.MipmapFilter = ((record.MipLevels > 1) || (record.MinFilter == .MipmapLinear))
			? .Linear : .Nearest;

		desc.AddressU = ToAddressMode(record.WrapU);
		desc.AddressV = ToAddressMode(record.WrapV);
		desc.AddressW = ToAddressMode(record.WrapW);

		// One is "off", and below one is meaningless, so it clamps rather than disabling
		// filtering outright.
		desc.MaxAnisotropy = (uint16)((record.Anisotropy < 1.0f) ? 1.0f : record.Anisotropy);
		return desc;
	}

	/// The mip half of the asset's filter is carried by MipmapFilter, so this reads only
	/// what it says about texels.
	public static FilterMode ToFilterMode(TextureFilter filter)
		=> ((filter == .Nearest) || (filter == .MipmapNearest)) ? .Nearest : .Linear;

	public static AddressMode ToAddressMode(TextureWrap wrap)
	{
		switch (wrap)
		{
		case .Repeat: return .Repeat;
		case .ClampToEdge: return .ClampToEdge;
		case .ClampToBorder: return .ClampToBorder;
		case .MirroredRepeat: return .MirrorRepeat;
		}
	}
}
