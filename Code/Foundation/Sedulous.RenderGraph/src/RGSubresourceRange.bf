using System;

namespace Sedulous.RenderGraph;

/// The slice of a texture an access covers, which is what lets two passes write different
/// shadow cascades of one array without the solver calling it a hazard.
///
/// A COUNT OF ZERO means everything remaining from the base, so a default range is the whole
/// resource and a caller that does not care about subresources never has to say so.
struct RGSubresourceRange
{
	public uint32 BaseMipLevel = 0;
	public uint32 MipLevelCount = 0;
	public uint32 BaseArrayLayer = 0;
	public uint32 ArrayLayerCount = 0;

	public this() {}

	public this(uint32 baseMipLevel, uint32 mipLevelCount, uint32 baseArrayLayer,
		uint32 arrayLayerCount)
	{
		BaseMipLevel = baseMipLevel;
		MipLevelCount = mipLevelCount;
		BaseArrayLayer = baseArrayLayer;
		ArrayLayerCount = arrayLayerCount;
	}

	public static RGSubresourceRange All => .();

	public bool IsAll =>
		(BaseMipLevel == 0) && (MipLevelCount == 0) && (BaseArrayLayer == 0) && (ArrayLayerCount == 0);

	/// Whether two ranges share any subresource, which is the question a hazard turns on.
	///
	/// The totals resolve the open ended counts, so a range that says everything and one that
	/// names a single mip still compare honestly.
	public bool Overlaps(RGSubresourceRange other, uint32 totalMips = 1, uint32 totalLayers = 1)
	{
		let myMipEnd = (MipLevelCount == 0) ? totalMips : (BaseMipLevel + MipLevelCount);
		let otherMipEnd = (other.MipLevelCount == 0)
			? totalMips : (other.BaseMipLevel + other.MipLevelCount);
		let myLayerEnd = (ArrayLayerCount == 0) ? totalLayers : (BaseArrayLayer + ArrayLayerCount);
		let otherLayerEnd = (other.ArrayLayerCount == 0)
			? totalLayers : (other.BaseArrayLayer + other.ArrayLayerCount);

		let mipsOverlap = (BaseMipLevel < otherMipEnd) && (other.BaseMipLevel < myMipEnd);
		let layersOverlap = (BaseArrayLayer < otherLayerEnd) && (other.BaseArrayLayer < myLayerEnd);
		return mipsOverlap && layersOverlap;
	}

	[Commutable]
	public static bool operator==(RGSubresourceRange a, RGSubresourceRange b) =>
		(a.BaseMipLevel == b.BaseMipLevel) && (a.MipLevelCount == b.MipLevelCount)
		&& (a.BaseArrayLayer == b.BaseArrayLayer) && (a.ArrayLayerCount == b.ArrayLayerCount);
}
